// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "EasyTask",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0")
    ],
    products: [
        .iOSApplication(
            name: "EasyTask",
            targets: ["EasyTask"],
            bundleIdentifier: "com.easytask.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .clock),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone,
                .mac
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .outgoingNetworkConnections(),
                .iCloud(services: [.cloudKit(containers: ["iCloud.com.easytask.app"])]),
                .events(calendars: [.read]),
                .userNotifications(options: [.alert, .badge, .sound])
            ],
            appCategory: .productivity
        )
    ],
    targets: [
        .executableTarget(
            name: "EasyTask",
            path: "Sources"
        )
    ]
)
