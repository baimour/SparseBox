import SwiftUI

struct AppItemView: View {
    let appDetails: [String : AnyCodable]
    var body: some View {
        Form {
            Section {
                ForEach(Array(appDetails.keys), id: \.self) { k in
                    let v = appDetails[k]?.value as? String
                    Text(k)
                        .badge("\(v ?? "(null)" )")
                        .textSelection(.enabled)
                }
            }
            Section {
                if let bundlePath = appDetails["Path"] {
                    Button("复制安装路径") {
                        UIPasteboard.general.string = "file://a\(bundlePath)"
                    }
                }
                if let containerPath = appDetails["Container"] {
                    Button("复制数据路径") {
                        UIPasteboard.general.string = "file://a\(containerPath)"
                    }
                }
            } header: {
                Text("任意读取漏洞")
            } footer: {
                Text("复制路径后，打开设置，将其粘贴到搜索栏中，再次全选并点击分享\n\n仅支持iOS 18.2b1及以下版本。文件夹只能通过隔空投送分享\n如果您分享App Store安装的应用，请注意，它仍会保持加密状态")
            }
        }
    }
}

struct AppListView: View {
    @State var apps: [String : AnyCodable] = [:]
    @State var searchString: String = ""
    var results: [String] {
        Array(searchString.isEmpty ? apps.keys : apps.filter {
            let appDetails = $0.value.value as? [String: AnyCodable]
            let appName = (appDetails!["CFBundleName"]?.value as! String?)!
            let appPath = (appDetails!["Path"]?.value as! String?)!
            return appName.contains(searchString) || appPath.contains(searchString)
        }.keys)
    }
    var body: some View {
        List {
            ForEach(results, id: \.self) { bundleID in
                let value = apps[bundleID]
                let appDetails = value?.value as? [String: AnyCodable]
                let appImage = appDetails!["PlaceholderIcon"]?.value as! Data?
                let appName = (appDetails!["CFBundleName"]?.value as! String?)!
                let appPath = (appDetails!["Path"]?.value as! String?)!
                NavigationLink {
                    AppItemView(appDetails: appDetails!)
                } label: {
                    Image(uiImage: UIImage(data: appImage!)!)
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text(appName)
                        Text(appPath).font(Font.footnote)
                    }
                }
            }
        }
        .onAppear {
            if apps.count == 0 {
                Task {
                    let deviceList = MobileDevice.deviceList()
                    guard deviceList.count == 1 else {
                        print("Invalid device count: \(deviceList.count)")
                        return
                    }
                    let udid = deviceList.first!
                    apps = MobileDevice.listApplications(udid: udid)!
                }
            }
        }
        .searchable(text: $searchString)
        .navigationTitle("应用列表")
    }
}
