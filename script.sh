#!/bin/bash

RETSTATUS=0
STATUS=0

# If iOS module exists, build
if [ -d "$MODULE_ROOT/ios/" ]; then

	echo
	echo "Building iOS version"
	echo

	cd $MODULE_ROOT/ios/
	cp $MODULE_ROOT/titanium.xcconfig titanium.xcconfig
	cat titanium.xcconfig
	./build.py

	let STATUS=$?
	if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
	  	let RETSTATUS=$STATUS
	else 
		# Test Module in a Titanium Application
		echo "Reading module manifest"
		MODULE_ID=$(sed -n 's/.*moduleid: \([^ ]*\).*/\1/p' manifest)
		MODULE_VERSION=$(sed -n 's/^version: \([^ ]*\).*/\1/p' manifest)
		echo "Module Info: " $MODULE_ID '@' $MODULE_VERSION

		#Install module
		echo "Installing module"
		ti sdk install $MODULE_ID*

		#This already happens in the previous script
		#echo "Downloading latest SDK"
		#ti sdk install
		#ti sdk select latest

		#Create new application
		echo "Creating new application"
		ti create -t app -p ios -d "./TestModule" -n "TestModule" --id "com.appc.TestModule" -u "http://appcelerator.com" --force
		cd ./TestModule/TestModule

		#Append module to manifest
		echo "Add module to application"
		sed -i "" 's/<modules>/&<module version="'$MODULE_VERSION'">'$MODULE_ID'<\/module>/g' tiapp.xml

		#echo "Copying module example"
		#cp -r $HOME/Library/Application\ Support/Titanium/modules/iphone/$MODULE_ID/$MODULE_VERSION/example/. ./Resources/

		#Append module to app.js
		cd ./Resources/
		echo -e "var moduleToTest = require('"$MODULE_ID"');\n$(cat app.js)" > app.js
		cd ../

		#Build application but do not run simulator
		echo "Build application"
		ti build -b -p ios -d "./"
	
		let STATUS=$?

		if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
			let RETSTATUS=$STATUS
		fi
	fi
fi

# if Android module exists, build
if [ -d "$MODULE_ROOT/android/" ]; then

  echo
  echo "Building Android version"
  echo

  cd $MODULE_ROOT/android/
  cp $MODULE_ROOT/build.properties build.properties
  cat build.properties
  
  # if lib folder doesn't exist, create it
  mkdir -p lib
  # if build folder doesn't exist, create it
  mkdir -p build
  # if build/docs folder doesn't exist, create it
  mkdir -p build/docs

  ant clean
  ant

  let STATUS=$?
  if (( "$RETSTATUS" == "0" )) && (( "$STATUS" != "0" )); then
    let RETSTATUS=$STATUS
  fi

  cd $MODULE_ROOT
  
fi

exit $RETSTATUS