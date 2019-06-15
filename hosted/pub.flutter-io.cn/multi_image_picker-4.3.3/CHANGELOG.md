# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

### Changed (v4.3.3)

## 2019-05-27

- Methods marked with @UiThread must be executed on the main thread. [#160](https://github.com/Sh1d0w/multi_image_picker/pull/160)

### Changed (v4.3.2)

## 2019-05-18

- Fix resolving gps metadata on Android [#153](https://github.com/Sh1d0w/multi_image_picker/pull/153)

### Changed (v4.3.1)

## 2019-05-13

- Updated FishBun to version 0.9.1

### Changed (v4.3.0)

## 2019-05-12

- Added new option `selectedAssets` which allows you to pre select Assets when opening the image picker

### Changed (v4.2.2)

## 2019-05-08

- Added option to customize the message when max selection limit is reached on Android

### Changed (v4.2.1)

## 2019-05-03

- Remove informationCollector from AssetThumbImageProvider to make the plugin work with latest master version of Flutter [info](https://github.com/flutter/flutter/issues/31962)

### Changed (v4.2.0)

## 2019-04-19

### iOS

- Updated BSImagePicker version to 2.10.0 and Switct version to 5.0

### Changed (v4.1.2)

## 2019-04-14

### Android

- Added an option to start Android picker in "All Photos" closes [#111](https://github.com/Sh1d0w/multi_image_picker/issues/111)
- Added selectCircleStrokeColor closes [#113](https://github.com/Sh1d0w/multi_image_picker/issues/113)

### Changed (v4.1.1)

## 2019-04-14

- Added `AssetThumb` widget, which simplified and handles displaying of thumb images.
- Added `AssetThumbProvider`

### BREAKING CHANGE
- Removed `Asset.thumbData` and `Asset.imageData` getters. They were obsolete as this data was returned from resolved future anyways, there is no point to keep them in the `Asset` object.
- Removed `Asset.releaseThumb`, `Asset.releaseOriginal` and `Asset.release` methods, as they are no longer needed.
- `Asset.requestThumbnail` and `Asset.requestOriginal` now return `Future<ByteData>` as previously returned `Future<dynamic>`

### Changed (v4.0.3)

## 2019-04-12

- Correctly return image name on photos taken with camera on Android

### Changed (v4.0.2)

## 2019-04-03

- Export MaterialOptions to make styling of Android possible.

### Changed (v4.0.1)

## 2019-03-28

- Fixed some deprecation warnings on Android

### Changed (v4.0.0)

## 2019-03-23
### Breaking change
- Replaced Mattise image picker with FishBun on Android. For migration guide see [here](https://sh1d0w.github.io/multi_image_picker/#/upgrading). [#95](https://github.com/Sh1d0w/multi_image_picker/pull/95)

### Changed (v3.0.23)

## 2019-03-12
- Fix Matisse version

### Changed (v3.0.22)

## 2019-03-02
- Send Thumb and Original image data via separate channels [#80](https://github.com/Sh1d0w/multi_image_picker/pull/80)

### Changed (v3.0.21)

## 2019-02-27
- Added ability to delete array of Assets from the filesystem [#79](https://github.com/Sh1d0w/multi_image_picker/pull/79)

### Changed (v3.0.14)

## 2019-02-17
- Fix failing build on Android

### Changed (v3.0.13)

## 2019-02-13
- Display only images in the picker on Android [#73](https://github.com/Sh1d0w/multi_image_picker/pull/73)

### Changed (v3.0.12)

## 2019-02-05
- Use custom fork of Matisse until it adds AndroidX support.


### Changed (v3.0.11)

## 2019-01-29
### BREAKING CHANGE
- Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to [also migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library.

### Changed (v2.4.11)

## 2019-01-23
### BREAKING CHANGE
- Renamed Metadata properties to lowerCamelCase in order to resolve https://github.com/dart-lang/sdk/issues/35732

### Changed (v2.3.33)

## 2019-01-23
- Correctly handle LensSpecification and SubjectArea metadata

### Changed (v2.3.32)

## 2019-01-14
- Fix possible bug with permissions on Android

### Changed (v2.3.31)

## 2019-01-12
- Add original image name to the Asset class

### Changed (v2.3.29)

## 2019-01-07
- Fix bug with permissions on Android

### Changed (v2.3.28)

## 2018-12-29
- Remove static_library definition on iOS

### Changed (v2.3.27)

## 2018-12-24
- Fix memory leak on Android

### Changed (v2.3.26)

## 2018-12-21
- Bump Android and iOS versions

### Changed (v2.3.25)

## 2018-12-21
- Pub page preview fixes

### Changed (v2.3.23)

## 2018-12-21
- Removed deprecated meta data tag on Android

### Changed (v2.3.22)

## 2018-12-20
- Added `requestMetadata()` method to the Asset class

### Changed (v2.3.01)

## 2018-12-18
- Added `takePhotoIcon` option to ios customization settings

### Changed (v2.3.00)

## 2018-12-13
### BREAKING CHANGE
- Android - renamed authorities to `android:authorities="YOUR_PACKAGE_NAME_HERE.multiimagepicker.fileprovider"`. Please update your manifest file to avoid errors.

### Changed (v2.2.61)

## 2018-12-13
- Added custom file provider to avoid collisions with other plugins. See README for example implementation

### Changed (v2.2.55)

## 2018-11-19
### Fixed
- Define module_headers as per http://blog.cocoapods.org/CocoaPods-1.5.0/

### Changed (v2.2.54)

## 2018-11-19
### Fixed
- Add s.static_framework = true as per https://github.com/flutter/flutter/issues/14161

### Changed (v2.2.53)

## 2018-11-08
### Fixed
- Added new optional parameter `quality` to `requestThumb` and `requestOriginal` methods.

### Changed (v2.2.52)

## 2018-11-07
### Fixed
- Don't rescale the image when decoding it on Android

### Changed (v2.2.50)

## 2018-11-07
### Fixed
- Correctly handle image orientation on Android phones [ref](https://stackoverflow.com/questions/14066038/why-does-an-image-captured-using-camera-intent-gets-rotated-on-some-devices-on-a?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa)

### Changed (v2.2.47)

## 2018-11-06
### Changed
- Increase thumb quality on Android

### Changed (v2.2.45)

## 2018-11-06
### Fixed
- Ask for CAMERA permission on Android, and fix opening of the picker after permission grant.

### Changed (v2.2.44)

## 2018-11-06
### Fixed
- Use correct application id on Android devices when setting up the camera provider

### Changed (v2.2.43)

## 2018-11-02
### Fixed
- requestOriginal now works correctly on Android

### Changed (v2.2.42)

## 2018-11-02
### Fixed
- Use app specific content provider, updated README.md

### Changed (v2.2.41)

## 2018-11-02
### Changed
- Commented out example file provider as it gets included in production bundle. If you want to test the example just uncomment it in the android manifest.

### Changed (v2.2.40)

## 2018-11-02
### Added
- Added new picker option `enableCamera` which allows the user to take pictures directly from the gallery. For more info how to enable this please see README.md

### Changed (v2.2.30)

## 2018-10-28
### Fixed
- iOS 12 and Swift 4.2 language fixes
- Important: In your XCode build setting you must set Swift Version to 4.2

### Changed (v2.2.10)

## 2018-09-19
### Changed
- Update Image picker library to support Swift 4.2 and XCode 10
- Remove obsolette file path in the asset class

### Changed (v2.1.26)

## 2018-09-10
### Fixed
- Fixed path not passed to the Asset class [#7](https://github.com/Sh1d0w/multi_image_picker/pull/7)

### Changed (v2.1.25)

## 2018-09-07
### Added
- Add Real file path and allow to refresh image gallery [#6](https://github.com/Sh1d0w/multi_image_picker/pull/6) (thanks CircleCurve)

### Changed (v2.1.23)

## 2018-08-31
### Added
- Improved the docs

### Changed (v2.1.22)

## 2018-08-28
### Added
- Add originalWidth, originalHeight, isPortrait and isLandscape getters for the Asset class

### Changed (v2.1.21)

## 2018-08-24
### Added
- Add release(), releaseOriginal() and releaseThumb() methods to help clean up the image data when it is no longer needed

### Changed (v2.1.02)

## 2018-08-20
### Fix
- Fix null pointer exception on Android when finishing from another activity (thanks to xia-weiyang)

### Changed (v2.1.01)

## 2018-08-16
### Change
- Add getters to Asset class

### Changed (v2.1.00)

## 2018-08-16
### BREAKING CHANGE
- Asset's `requestThumbnail` and `requestOriginal` methods now will return Future<ByteData>. Removed the method callbacks.

### Changed (v2.0.04)

## 2018-08-16
### Fixed
- Correctly crop the thumb on iOS

### Changed (v2.0.03)

## 2018-08-16
### Added
- Allow network access to download images present only in iCloud

### Changed (v2.0.02)

## 2018-08-16
### Fixed
- Improve thumbs quality on iOS to always deliver best of it

### Changed (v2.0.01)

## 2018-08-16
### Fixed
- Fix picking original image on Android was not triggering properly the callback

### Changed (v2.0.0)

## 2018-08-15
### BREAKING CHANGE
- The plugin have been redesigned to be more responsive and flexible.
- pickImages method will no longer return List<File>, instead it will return List<Asset>
- You can then request asset thumbnails or the original image, which will load asyncrhoniously without blocking the main UI thred. For more info see the examples directory.

### Added
- `Asset` class, with methods `requestThumbnail(int width, int height, callback)` and `requestOriginal(callback)`

### Changed (v1.0.53)

## 2018-08-13
### Fixed
- Fix crash on iOS when picking a lot of images.

### Changed (v1.0.52)

## 2018-08-12
### Fixed
- Picking images on iOS now will properly handle PHAssets

### Changed (v1.0.51)

## 2018-08-07
### Changed
- Fix a crash on Android caused by closing and reopening the gallery

### Changed (v1.0.5)

## 2018-08-07
### Add
- Support iOS and Android customizations

### Changed (v1.0.4)

## 2018-08-06
### Changed
- iOS: Add missing super.init() call in the class constructor

### Changed (v1.0.3)

## 2018-08-05
### Changed
- Changed sdk: ">=2.0.0-dev.28.0 <3.0.0"

### Changed (v1.0.2)

## 2018-08-05
### Added
- Add Support for Dart 2 in pubspec.yaml file

### Changed (v1.0.1)

## 2018-08-05
### Added
- Initial release with basic support for iOS and Android
