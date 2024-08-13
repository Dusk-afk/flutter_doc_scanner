import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftFlutterDocScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
   var resultChannel :FlutterResult?
   var presentingController: VNDocumentCameraViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_doc_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterDocScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.resultChannel = result
    self.presentingController = VNDocumentCameraViewController()
    if call.method == "getScanDocuments" {
        let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        self.presentingController!.delegate = self
        presentedVC?.present(self.presentingController!, animated: true)
    } else if call.method == "isSupported" {
        self.resultChannel?(VNDocumentCameraViewController.isSupported)
    } else {
        result(FlutterMethodNotImplemented)
        return
    }
  }


    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let tempDirPath = self.getDocumentsDirectory()
        let currentDateTime = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let formattedDate = df.string(from: currentDateTime)
        var filenames: [String] = []
        for i in 0 ... scan.pageCount - 1 {
            let page = scan.imageOfPage(at: i)
            let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).png")
            try? page.pngData()?.write(to: url)
            filenames.append(url.path)
        }
        resultChannel?(filenames)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }
}
