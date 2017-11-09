
# react-native-autoupdate

## Getting started

`$ npm install react-native-autoupdate --save`

### Mostly automatic installation

`$ react-native link react-native-autoupdate`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-autoupdate` and add `RNAutoupdate.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNAutoupdate.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNAutoupdatePackage;` to the imports at the top of the file
  - Add `new RNAutoupdatePackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-autoupdate'
  	project(':react-native-autoupdate').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-autoupdate/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-autoupdate')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNAutoupdate.sln` in `node_modules/react-native-autoupdate/windows/RNAutoupdate.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Autoupdate.RNAutoupdate;` to the usings at the top of the file
  - Add `new RNAutoupdatePackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNAutoupdate from 'react-native-autoupdate';

// TODO: What to do with the module?
RNAutoupdate;
```
  