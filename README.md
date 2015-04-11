# Tessie
Voice assist for Tesla Model S.

Note: This software is very early alpha. Don't crash your Tesla please.

## Requirements
- iPhone with iOS 7+
- XCode 6.1
- OpenEars Voice Recognition/Synthesis: http://www.politepix.com/openears/
- Arduino with BLE shield (Blend Micro: http://redbearlab.com/blendmicro/)
- Arduino IDE: http://arduino.cc/en/main/software

## Installation

### XCode
- Open Tessie.xcodeproj
- Download [OpenEars](http://www.politepix.com/openears/#Installation) distribution.
- Inside the downloaded distribution there is a folder called "Framework". Drag the "Framework" folder into the Tessie project in Xcode.
- Compile and run the app on your phone

### Arduino IDE
- Open Arduino/BLEMouseControl/BLEMouseControl.ino
- Compile and upload to Arduino Board

## Usage
- plug Arduino BLE board into your Tesla Model S (USB port)
- Launch Tessie app
- Select commands or say them

## Supported Commands
- Show Media
- Show Navigation
- Show Calendar
- Show Energy
- Show Web
- Show Camera
- Show Phone
- Garage Door
- Show Battery
- Show Controls
- Close Sunroof
- Vent Sunroof
- Open Sunroof 75%
- Open Sunroof

see [Command Configuration](Tessie/commands.json)

## License
- MIT

