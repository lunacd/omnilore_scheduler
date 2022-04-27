# Omnilore Scheduler

A course scheduler for Omnilore.

## Documentation

Developer documentation is available [here](https://andyliuhaowen.github.io/omnilore_documentation/).

## Dev Environment Setup

You need to install Flutter to further develop this program. Flutter installation guide is available [here](https://docs.flutter.dev/get-started/install).
As for your IDE, one of IntelliJ IDEA, Android Studio, and VS Code is recommended. See guide [here](https://docs.flutter.dev/get-started/editor).
Verify your setup with:
```
flutter doctor
```
and address any issue it points out.

## Running and Testing

You should be able to run, debug, and unit-test the program with IDE features (some sort of run button, depending on your IDE of choice).

Should the need arise, run the program with:
```
flutter run -d <windows/macOS/linux>
```

Run unit tests with
```
flutter run test
```

## Building Executables

Build executables with:
```
flutter build <windows/macOS/linux>
```

After succeeding, the executable is available under `build/<windows/macOS/linux>/x64/release/bundle`.
That folder includes all the necessary libraries and data files that the generated executable depends on.
Please distribute the entire folder.
