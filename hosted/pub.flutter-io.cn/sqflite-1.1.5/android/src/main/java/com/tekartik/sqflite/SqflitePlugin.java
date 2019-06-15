package com.tekartik.sqflite;

import android.annotation.SuppressLint;
import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteCantOpenDatabaseException;
import android.database.sqlite.SQLiteDatabase;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Process;
import android.util.Log;

import com.tekartik.sqflite.dev.Debug;
import com.tekartik.sqflite.operation.BatchOperation;
import com.tekartik.sqflite.operation.ExecuteOperation;
import com.tekartik.sqflite.operation.MethodCallOperation;
import com.tekartik.sqflite.operation.Operation;
import com.tekartik.sqflite.operation.SqlErrorInfo;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static com.tekartik.sqflite.Constant.ERROR_BAD_PARAM;
import static com.tekartik.sqflite.Constant.MEMORY_DATABASE_PATH;
import static com.tekartik.sqflite.Constant.METHOD_BATCH;
import static com.tekartik.sqflite.Constant.METHOD_CLOSE_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_DEBUG_MODE;
import static com.tekartik.sqflite.Constant.METHOD_EXECUTE;
import static com.tekartik.sqflite.Constant.METHOD_GET_DATABASES_PATH;
import static com.tekartik.sqflite.Constant.METHOD_GET_PLATFORM_VERSION;
import static com.tekartik.sqflite.Constant.METHOD_INSERT;
import static com.tekartik.sqflite.Constant.METHOD_OPEN_DATABASE;
import static com.tekartik.sqflite.Constant.METHOD_OPTIONS;
import static com.tekartik.sqflite.Constant.METHOD_QUERY;
import static com.tekartik.sqflite.Constant.METHOD_UPDATE;
import static com.tekartik.sqflite.Constant.PARAM_ID;
import static com.tekartik.sqflite.Constant.PARAM_OPERATIONS;
import static com.tekartik.sqflite.Constant.PARAM_PATH;
import static com.tekartik.sqflite.Constant.PARAM_READ_ONLY;
import static com.tekartik.sqflite.Constant.PARAM_RECOVERED;
import static com.tekartik.sqflite.Constant.PARAM_SINGLE_INSTANCE;
import static com.tekartik.sqflite.Constant.PARAM_SQL;
import static com.tekartik.sqflite.Constant.PARAM_SQL_ARGUMENTS;
import static com.tekartik.sqflite.Constant.TAG;

/**
 * SqflitePlugin Android implementation
 */
public class SqflitePlugin implements MethodCallHandler {

    static final Map<String, Integer> _singleInstancesByPath = new HashMap<>();
    static private boolean QUERY_AS_MAP_LIST = false; // set by options
    static private int THREAD_PRIORITY = Process.THREAD_PRIORITY_BACKGROUND;
    private final Object databaseMapLocker = new Object();
    // local cache
    String databasesPath;
    private Context context;
    private int databaseOpenCount = 0;
    private int databaseId = 0; // incremental database id
    // Database thread execution
    private HandlerThread handlerThread;
    private Handler handler;
    @SuppressLint("UseSparseArrays")
    private final Map<Integer, Database> databaseMap = new HashMap<>();

    SqflitePlugin(Context context) {
        this.context = context;
    }

    //
    // Plugin registration.
    //
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.tekartik.sqflite");
        channel.setMethodCallHandler(new SqflitePlugin(registrar.context()));
    }

    private static Object cursorValue(Cursor cursor, int index) {
        switch (cursor.getType(index)) {
            case Cursor.FIELD_TYPE_NULL:
                return null;
            case Cursor.FIELD_TYPE_INTEGER:
                return cursor.getLong(index);
            case Cursor.FIELD_TYPE_FLOAT:
                return cursor.getDouble(index);
            case Cursor.FIELD_TYPE_STRING:
                return cursor.getString(index);
            case Cursor.FIELD_TYPE_BLOB:
                return cursor.getBlob(index);
        }
        return null;
    }

    private static List<Object> cursorRowToList(Cursor cursor, int length) {
        List<Object> list = new ArrayList<>(length);

        for (int i = 0; i < length; i++) {
            Object value = cursorValue(cursor, i);
            if (Debug.EXTRA_LOGV) {
                Log.d(TAG, "column " + i + " " + cursor.getType(i) + ": " + value);
            }
            list.add(value);
        }
        return list;
    }

    private static Map<String, Object> cursorRowToMap(Cursor cursor) {
        Map<String, Object> map = new HashMap<>();
        String[] columns = cursor.getColumnNames();
        int length = columns.length;
        for (int i = 0; i < length; i++) {
            if (Debug.EXTRA_LOGV) {
                Log.d(TAG, "column " + i + " " + cursor.getType(i));
            }
            switch (cursor.getType(i)) {
                case Cursor.FIELD_TYPE_NULL:
                    map.put(columns[i], null);
                    break;
                case Cursor.FIELD_TYPE_INTEGER:
                    map.put(columns[i], cursor.getLong(i));
                    break;
                case Cursor.FIELD_TYPE_FLOAT:
                    map.put(columns[i], cursor.getDouble(i));
                    break;
                case Cursor.FIELD_TYPE_STRING:
                    map.put(columns[i], cursor.getString(i));
                    break;
                case Cursor.FIELD_TYPE_BLOB:
                    map.put(columns[i], cursor.getBlob(i));
                    break;
            }
        }
        return map;
    }

    static private Map<String, Object> fixMap(Map<Object, Object> map) {
        Map<String, Object> newMap = new HashMap<>();
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object value = entry.getValue();
            if (value instanceof Map) {
                @SuppressWarnings("unchecked")
                Map<Object, Object> mapValue = (Map<Object, Object>) value;
                value = fixMap(mapValue);
            } else {
                value = toString(value);
            }
            newMap.put(toString(entry.getKey()), value);
        }
        return newMap;
    }

    // Convert a value to a string
    // especially byte[]
    static private String toString(Object value) {
        if (value == null) {
            return null;
        } else if (value instanceof byte[]) {
            List<Integer> list = new ArrayList<>();
            for (byte _byte : (byte[]) value) {
                list.add((int) _byte);
            }
            return list.toString();
        } else if (value instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<Object, Object> mapValue = (Map<Object, Object>) value;
            return fixMap(mapValue).toString();
        } else {
            return value.toString();
        }
    }

    static boolean isInMemoryPath(String path) {
        return (path == null || path.equals(MEMORY_DATABASE_PATH));
    }

    private Context getContext() {
        return context;
    }

    private Database getDatabase(int databaseId) {
        return databaseMap.get(databaseId);
    }

    private Database getDatabaseOrError(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabase(databaseId);

        if (database != null) {
            return database;
        } else {
            result.error(Constant.SQLITE_ERROR, Constant.ERROR_DATABASE_CLOSED + " " + databaseId, null);
            return null;
        }
    }

    private SqlCommand getSqlCommand(MethodCall call) {
        String sql = call.argument(PARAM_SQL);
        List<Object> arguments = call.argument(PARAM_SQL_ARGUMENTS);
        return new SqlCommand(sql, arguments);
    }

    private Database executeOrError(Database database, MethodCall call, Result result) {
        SqlCommand command = getSqlCommand(call);
        return executeOrError(database, command, result);
    }

    private boolean executeOrError(Database database, Operation operation) {
        SqlCommand command = operation.getSqlCommand();
        if (Debug.LOGV) {
            Log.d(TAG, "[" + database.getThreadLogTag() + "] " + command);
        }
        try {
            database.getWritableDatabase().execSQL(command.getSql(), command.getSqlArguments());
            return true;
        } catch (Exception exception) {
            handleException(exception, operation, database);
            return false;
        }
    }

    private Database executeOrError(Database database, SqlCommand command, Result result) {
        if (Debug.LOGV) {
            Log.d(TAG, "[" + database.getThreadLogTag() + "] " + command);
        }
        try {
            database.getWritableDatabase().execSQL(command.getSql(), command.getSqlArguments());
        } catch (Exception exception) {
            Operation operation = new ExecuteOperation(result, command);
            handleException(exception, operation, database);
            return null;
        }
        return database;
    }

    //
    // query
    //
    private void onQueryCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {
                MethodCallOperation operation = new MethodCallOperation(call, bgResult);
                query(database, operation);

            }
        });
    }

    //
    // Sqflite.batch
    //
    private void onBatchCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {

                MethodCallOperation mainOperation = new MethodCallOperation(call, bgResult);
                boolean noResult = mainOperation.getNoResult();
                boolean continueOnError = mainOperation.getContinueOnError();

                List<Map<String, Object>> operations = call.argument(PARAM_OPERATIONS);
                List<Map<String, Object>> results = new ArrayList<>();

                //devLog(TAG, "operations " + operations);
                for (Map<String, Object> map : operations) {
                    //devLog(TAG, "map " + map);
                    BatchOperation operation = new BatchOperation(map, noResult);
                    String method = operation.getMethod();
                    switch (method) {
                        case METHOD_EXECUTE:
                            if (execute(database, operation)) {
                                //devLog(TAG, "results: " + operation.getBatchResults());
                                operation.handleSuccess(results);
                            } else if (continueOnError) {
                                operation.handleErrorContinue(results);
                            } else {
                                // we stop at the first error
                                operation.handleError(bgResult);
                                return;
                            }
                            break;
                        case METHOD_INSERT:
                            if (insert(database, operation)) {
                                //devLog(TAG, "results: " + operation.getBatchResults());
                                operation.handleSuccess(results);
                            } else if (continueOnError) {
                                operation.handleErrorContinue(results);
                            } else {
                                // we stop at the first error
                                operation.handleError(bgResult);
                                return;
                            }
                            break;
                        case METHOD_QUERY:
                            if (query(database, operation)) {
                                //devLog(TAG, "results: " + operation.getBatchResults());
                                operation.handleSuccess(results);
                            } else if (continueOnError) {
                                operation.handleErrorContinue(results);
                            } else {
                                // we stop at the first error
                                operation.handleError(bgResult);
                                return;
                            }
                            break;
                        case METHOD_UPDATE:
                            if (update(database, operation)) {
                                //devLog(TAG, "results: " + operation.getBatchResults());
                                operation.handleSuccess(results);
                            } else if (continueOnError) {
                                operation.handleErrorContinue(results);
                            } else {
                                // we stop at the first error
                                operation.handleError(bgResult);
                                return;
                            }
                            break;
                        default:
                            bgResult.error(ERROR_BAD_PARAM, "Batch method '" + method + "' not supported", null);
                            return;
                    }
                }
                // Set the results of all operations
                // devLog(TAG, "results " + results);
                if (noResult) {
                    bgResult.success(null);
                } else {
                    bgResult.success(results);
                }
            }
        });
    }

    // Return true on success
    private boolean execute(Database database, final Operation operation) {
        if (!executeOrError(database, operation)) {
            return false;
        }
        operation.success(null);
        return true;
    }

    // Return true on success
    private boolean insert(Database database, final Operation operation) {
        if (!executeOrError(database, operation)) {
            return false;
        }
        // don't get last id if not expected
        if (operation.getNoResult()) {
            operation.success(null);
            return true;
        }

        Cursor cursor = null;
        // Read both the changes and last insert row id in on sql call
        String sql = "SELECT changes(), last_insert_rowid()";

        // Handle ON CONFLICT but ignore error, issue #164
        // Read the number of changes before getting the inserted id
        try {
            SQLiteDatabase db = database.getWritableDatabase();

            cursor = db.rawQuery(sql, null);
            if (cursor != null && cursor.getCount() > 0 && cursor.moveToFirst()) {
                final int changed = cursor.getInt(0);

                // If the change count is 0, assume the insert failed
                // and return null
                if (changed == 0) {
                    if (Debug.LOGV) {
                        Log.d(TAG, "no changes (id was " + cursor.getLong(1) + ")");
                    }
                    operation.success(null);
                    return true;
                } else {
                    final long id = cursor.getLong(1);
                    if (Debug.LOGV) {
                        Log.d(TAG, "inserted " + id);
                    }
                    operation.success(id);
                    return true;
                }
            } else {
                Log.e(TAG, "fail to read changes for Insert");
            }
            operation.success(null);
            return true;
        } catch (Exception exception) {
            handleException(exception, operation, database);
            return false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }

    // Return true on success
    private boolean query(Database database, final Operation operation) {
        SqlCommand command = operation.getSqlCommand();

        List<Map<String, Object>> results = new ArrayList<>();
        Map<String, Object> newResults = null;
        List<List<Object>> rows = null;
        int newColumnCount = 0;
        if (Debug.LOGV) {
            Log.d(TAG, "[" + Thread.currentThread() + "] " + command);
        }
        Cursor cursor = null;
        boolean queryAsMapList = QUERY_AS_MAP_LIST;
        try {
            // For query we sanitize as it only takes String which does not work
            // for references. Simply embed the int/long into the query itself
            command = command.sanitizeForQuery();

            cursor = database.getReadableDatabase().rawQuery(command.getSql(), command.getQuerySqlArguments());
            while (cursor.moveToNext()) {
                if (queryAsMapList) {
                    Map<String, Object> map = cursorRowToMap(cursor);
                    if (Debug.LOGV) {
                        Log.d(TAG, SqflitePlugin.toString(map));
                    }
                    results.add(map);
                } else {
                    if (newResults == null) {
                        rows = new ArrayList<>();
                        newResults = new HashMap<>();
                        newColumnCount = cursor.getColumnCount();
                        newResults.put("columns", Arrays.asList(cursor.getColumnNames()));
                        newResults.put("rows", rows);
                    }
                    rows.add(cursorRowToList(cursor, newColumnCount));
                }
            }
            if (queryAsMapList) {
                operation.success(results);
            } else {
                // Handle empty
                if (newResults == null) {
                    newResults = new HashMap<>();
                }
                operation.success(newResults);
            }
            return true;

        } catch (Exception exception) {
            handleException(exception, operation, database);
            return false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }

    //
    // Insert
    //
    private void onInsertCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {
                MethodCallOperation operation = new MethodCallOperation(call, bgResult);
                insert(database, operation);
            }

        });
    }

    //
    // Sqflite.execute
    //
    private void onExecuteCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {

                if (executeOrError(database, call, bgResult) == null) {
                    return;
                }
                bgResult.success(null);
            }
        });
    }

    // Return true on success
    private boolean update(Database database, final Operation operation) {
        if (!executeOrError(database, operation)) {
            return false;
        }
        // don't get last id if not expected
        if (operation.getNoResult()) {
            operation.success(null);
            return true;
        }
        Cursor cursor = null;
        try {
            SQLiteDatabase db = database.getWritableDatabase();

            cursor = db.rawQuery("SELECT changes()", null);
            if (cursor != null && cursor.getCount() > 0 && cursor.moveToFirst()) {
                final int changed = cursor.getInt(0);
                if (Debug.LOGV) {
                    Log.d(TAG, "changed " + changed);
                }
                operation.success(changed);
                return true;
            } else {
                Log.e(TAG, "fail to read changes for Update/Delete");
            }
            operation.success(null);
            return true;
        } catch (Exception e) {
            handleException(e, operation, database);
            return false;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }

    //
    // Sqflite.update
    //
    private void onUpdateCall(final MethodCall call, Result result) {

        final Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        final BgResult bgResult = new BgResult(result);
        handler.post(new Runnable() {
            @Override
            public void run() {
                MethodCallOperation operation = new MethodCallOperation(call, bgResult);
                update(database, operation);
            }
        });
    }

    private void handleException(Exception exception, Operation operation, Database database) {
        if (exception instanceof SQLiteCantOpenDatabaseException) {
            operation.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + database.path, null);
            return;
        } else if (exception instanceof SQLException) {
            operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
            return;
        }
        operation.error(Constant.SQLITE_ERROR, exception.getMessage(), SqlErrorInfo.getMap(operation));
    }

    // {
    // 'id': xxx
    // 'recovered': true // if recovered only for single instance
    // }
    static Map makeOpenResult(int databaseId, boolean recovered) {
        Map<String, Object> result = new HashMap<>();
        result.put(PARAM_ID, databaseId);
        if (recovered) {
            result.put(PARAM_RECOVERED, true);
        }
        return result;
    }

    //
    // Sqflite.open
    //
    private void onOpenDatabaseCall(MethodCall call, Result result) {
        String path = call.argument(PARAM_PATH);
        Boolean readOnly = call.argument(PARAM_READ_ONLY);
        boolean inMemory = isInMemoryPath(path);

        boolean singleInstance = !Boolean.FALSE.equals(call.argument(PARAM_SINGLE_INSTANCE)) && !inMemory;

        // For single instance we create or reuse a thread right away
        // DO NOT TRY TO LOAD existing instance, the database has been closed


        if (singleInstance) {
            // Look for in memory instance
            synchronized (databaseMapLocker) {
                if (Debug.EXTRA_LOGV) {
                    Log.d(Constant.TAG, "Look for " + path + " in " + _singleInstancesByPath.keySet());
                }
                Integer databaseId = _singleInstancesByPath.get(path);
                if (databaseId != null) {
                    Database database = databaseMap.get(databaseId);
                    if (database != null) {
                        if (!database.sqliteDatabase.isOpen()) {
                            if (Debug.LOGV) {
                                Log.d(Constant.TAG, "[" + Thread.currentThread() + "] single instance database of " + path + " not opened");
                            }
                        } else {

                            if (Debug.LOGV) {
                                Log.d(Constant.TAG, "[" + Thread.currentThread() + "] re-opened single instance " + databaseId + " " + path + " total open count (" + databaseOpenCount + ")");
                            }
                            result.success(makeOpenResult(databaseId, true));
                            return;
                        }
                    }
                }
            }
        }


        if (!inMemory) {
            File file = new File(path);
            File directory = new File(file.getParent());
            if (!directory.exists()) {
                if (!directory.mkdirs()) {
                    if (!directory.exists()) {
                        result.error(Constant.SQLITE_ERROR, Constant.ERROR_OPEN_FAILED + " " + path, null);
                        return;
                    }
                }
            }
        }

        int databaseId;
        synchronized (databaseMapLocker) {
            databaseId = ++this.databaseId;
        }
        Database database = new Database(context, path, databaseId, singleInstance);
        // force opening
        try {
            if (Boolean.TRUE.equals(readOnly)) {
                database.openReadOnly();
            } else {
                database.open();
            }
        } catch (Exception e) {
            MethodCallOperation operation = new MethodCallOperation(call, result);
            handleException(e, operation, database);
            return;
        }

        //SQLiteDatabase sqLiteDatabase = SQLiteDatabase.openDatabase(path, null, 0);
        synchronized (databaseMapLocker) {
            if (databaseOpenCount++ == 0) {
                handlerThread = new HandlerThread("Sqflite", SqflitePlugin.THREAD_PRIORITY);
                handlerThread.start();
                //TEST UI  Handler
                //handler = new Handler();
                handler = new Handler(handlerThread.getLooper());
                if (Debug.LOGV) {
                    Log.d(TAG, "starting thread" + handlerThread + " priority " + SqflitePlugin.THREAD_PRIORITY);
                }
            }
            if (singleInstance) {
                _singleInstancesByPath.put(path, databaseId);
            }
            databaseMap.put(databaseId, database);
            if (Debug.LOGV) {
                Log.d(TAG, "[" + Thread.currentThread() + "] opened " + databaseId + " " + path + " total open count (" + databaseOpenCount + ")");
            }
        }

        result.success(makeOpenResult(databaseId, false));
    }

    //
    // Sqflite.close
    //
    private void onCloseDatabaseCall(MethodCall call, Result result) {
        int databaseId = call.argument(PARAM_ID);
        Database database = getDatabaseOrError(call, result);
        if (database == null) {
            return;
        }
        if (Debug.LOGV) {
            Log.d(TAG, "[" + Thread.currentThread() + "] closing " + databaseId + " " + database.path + " total open count (" + databaseOpenCount + ")");
        }
        String path = database.path;
        if (database.singleInstance) {
            // Remove from single instance map
            synchronized (databaseMapLocker) {
                _singleInstancesByPath.remove(path);
            }
        }
        database.close();

        synchronized (databaseMapLocker) {
            databaseMap.remove(databaseId);
            if (--databaseOpenCount == 0) {
                if (Debug.LOGV) {
                    Log.d(TAG, "stopping thread" + handlerThread);
                }
                handlerThread.quit();
                handlerThread = null;
                handler = null;
            }
        }


        result.success(null);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            // quick testing
            case METHOD_GET_PLATFORM_VERSION:
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case METHOD_DEBUG_MODE: {
                Object on = call.arguments();
                Debug.LOGV = Boolean.TRUE.equals(on);
                Debug.EXTRA_LOGV = Debug._EXTRA_LOGV && Debug.LOGV;
                result.success(null);
                break;
            }
            case METHOD_CLOSE_DATABASE: {
                onCloseDatabaseCall(call, result);
                break;
            }
            case METHOD_QUERY: {
                onQueryCall(call, result);
                break;
            }
            case METHOD_INSERT: {
                onInsertCall(call, result);
                break;
            }
            case METHOD_UPDATE: {
                onUpdateCall(call, result);
                break;
            }
            case METHOD_EXECUTE: {
                onExecuteCall(call, result);
                break;
            }
            case METHOD_OPEN_DATABASE: {
                onOpenDatabaseCall(call, result);
                break;
            }
            case METHOD_BATCH: {
                onBatchCall(call, result);
                break;
            }
            case METHOD_OPTIONS: {
                onOptionsCall(call, result);
                break;
            }
            case METHOD_GET_DATABASES_PATH: {
                onGetDatabasesPath(call, result);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    void onOptionsCall(final MethodCall call, Result result) {
        Object paramAsList = call.argument(Constant.PARAM_QUERY_AS_MAP_LIST);
        if (paramAsList != null) {
            QUERY_AS_MAP_LIST = Boolean.TRUE.equals(paramAsList);
        }
        Object threadPriority = call.argument(Constant.PARAM_THREAD_PRIORITY);
        if (threadPriority != null) {
            THREAD_PRIORITY = (Integer) threadPriority;
        }
        result.success(null);
    }

    //private static class Database

    void onGetDatabasesPath(final MethodCall call, Result result) {
        if (databasesPath == null) {
            String dummyDatabaseName = "tekartik_sqflite.db";
            File file = context.getDatabasePath(dummyDatabaseName);
            databasesPath = file.getParent();
        }
        result.success(databasesPath);
    }

    private static class Database {
        final boolean singleInstance;
        final String path;
        final int id;
        SQLiteDatabase sqliteDatabase;

        private Database(Context context, String path, int id, boolean singleInstance) {
            this.path = path;
            this.singleInstance = singleInstance;
            this.id = id;
        }

        private void open() {
            sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                    SQLiteDatabase.CREATE_IF_NECESSARY);
        }

        private void openReadOnly() {
            sqliteDatabase = SQLiteDatabase.openDatabase(path, null,
                    SQLiteDatabase.OPEN_READONLY);
        }

        public void close() {
            sqliteDatabase.close();
        }

        public SQLiteDatabase getWritableDatabase() {
            return sqliteDatabase;
        }

        public SQLiteDatabase getReadableDatabase() {
            return sqliteDatabase;
        }

        public boolean enableWriteAheadLogging() {
            try {
                return sqliteDatabase.enableWriteAheadLogging();
            } catch (Exception e) {
                Log.e(TAG, "enable WAL error: " + e);
                return false;
            }
        }

        String getThreadLogTag() {
            Thread thread = Thread.currentThread();

            return "" + id + "," + thread.getName() + "(" + thread.getId() + ")";
        }
    }

    private class BgResult implements Result {
        // Caller handler
        final Handler handler = new Handler();
        private final Result result;

        private BgResult(Result result) {
            this.result = result;
        }

        // make sure to respond in the caller thread
        public void success(final Object results) {

            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.success(results);
                }
            });
        }

        public void error(final String errorCode, final String errorMessage, final Object data) {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.error(errorCode, errorMessage, data);
                }
            });
        }

        @Override
        public void notImplemented() {
            handler.post(new Runnable() {
                @Override
                public void run() {
                    result.notImplemented();
                }
            });
        }
    }
}
