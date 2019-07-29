
import UIKit
import AVFoundation
import SwiftyStoreKit
import UserNotifications
import NVActivityIndicatorView
import IRLDocumentScanner
import PhoneNumberKit
import Foundation
import SystemConfiguration

//import GPUImage

var server_ID = ""
var isForiPhone6Plus : Bool!
var isThisForiPad : Bool!
var isForiPhone6 : Bool!
var isForiPhone5 : Bool!
var Cover_Edited : Bool!
var isCheckingFaxStatus: Bool! = false
var isFaxStatusCountOne: Bool! = false
var isTapNewFaxButton: Bool! = false
var alertSuccessFax : UIAlertController!
var alertFailedFax : UIAlertController!
//var spinner : UIActivityIndicatorView!
var wizardController : WizardViewController!
var progressView : UIProgressView?
var DefaultCountryID = ""
var UrlPath : URL!
var myString : String = ""
var outboundFaxlistData : Outbound_messages?
// The output below is limited by 4 KB.
// Upgrade your plan to remove this limitation.
//1B96D6
var splashBackgroundView : UIImageView!
var SplashImageview : UIImageView!
var outerCompltion : (()->())?
var statusBarNotification = StatusBarNotification()

extension UIWindow :CAAnimationDelegate
{
    func addsplashview(compltion:@escaping (()->()))
    {
        outerCompltion = compltion
        splashBackgroundView = UIImageView(frame:(self.screen.bounds))
        splashBackgroundView.image = UIImage(named:"BlankSplashImage")
        self.addSubview(splashBackgroundView)
        var width : CGFloat = 0
        var height : CGFloat = 0
        if isThisForiPad == true
        {
            width = 400
            height = 400
        }
        else
        {
            width = 200
            height = 200
        }
        
        
        let jeremyGif = UIImage.gif(name:"SplashScreen")
        SplashImageview = UIImageView(frame:CGRect(x: splashBackgroundView.frame.size.width/2, y:splashBackgroundView.frame.size.height/2, width: width, height: height))
        splashBackgroundView.addSubview(SplashImageview)
        SplashImageview.center = splashBackgroundView.center
        var values = [CGImage]()
        for image in jeremyGif!.images! {
            values.append(image.cgImage!)
        }
        
        // Create animation and set SwiftGif values and duration
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.calculationMode = kCAAnimationDiscrete
        animation.duration = 1.5
        animation.values = values
        // Set the repeat count
        animation.repeatCount = 1
        // Other stuff
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        // Set the delegate
        animation.delegate = self
        SplashImageview.layer.add(animation, forKey: "animation")
        
       
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        if flag
        {
            if (outerCompltion != nil)
            {
                splashBackgroundView.removeFromSuperview()
                    DispatchQueue.main.async
                    {
                        outerCompltion!()
                    }
            }
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

func DLog(_ items: Any..., separator: String = "", terminator: String = "\n") {
    #if DEBUG
        //        Swift.print(items[0], separator:separator, terminator: terminator)
        let currentDate = Date()
        let CurrentTimeZone = NSTimeZone(abbreviation: "GMT")
        let SystemTimeZone = NSTimeZone.system
        let currentGMTOffset: Int = CurrentTimeZone!.secondsFromGMT(for: currentDate)
        let SystemGMTOffset: Int = SystemTimeZone.secondsFromGMT(for: currentDate)
        let interval: TimeInterval = TimeInterval(SystemGMTOffset - currentGMTOffset)
        
        let TodayDate = Date(timeInterval: interval, since: currentDate)
        Swift.print(TodayDate,": ",items[0], separator:separator, terminator: terminator)
    #endif
}

//func DLog(_ message: String, function: String = #function)
//{
//    #if DEBUG
////        print("\(function): \(message)")
//        NSLog("\(function): \(message)")
//    #endif
//}

func removeSpecialCharacterFromFileName(fileName:String) -> String
{
    var fileName : String = fileName.components(separatedBy: NSCharacterSet.illegalCharacters).joined(separator: "")
    fileName = fileName.components(separatedBy: NSCharacterSet.symbols).joined(separator: "")
    fileName = fileName.components(separatedBy: NSCharacterSet.controlCharacters).joined(separator: "")
    fileName = fileName.components(separatedBy: NSCharacterSet.decomposables).joined(separator: "")
    fileName = fileName.replacingOccurrences(of: ",", with: "")
    fileName = fileName.replacingOccurrences(of: "%20", with: "")
    fileName = fileName.replacingOccurrences(of: "%2520", with: "")
    fileName = fileName.replacingOccurrences(of: " ", with: "")

    return fileName
}

func supportsFile(fileName: String, fromExt arr: [AnyObject]) -> Bool
{
    for i in 0 ..< arr.count
    {
        let ext: String = arr[i] as! String
        if fileName.uppercased().hasSuffix(ext.uppercased()){
            return true
        }
    }
    return false
}

//MARK: Loading AlertView

func showLoadingAlert(_ title : String, networkIndicator network : Bool)
{
    if let value = UIApplication.topViewController()
    {
        stopSpinner()
        if value is UIAlertController
        {
            return
        }
        if network
        {
            NetworkActivityIndicatorManager.start()
        }
            let alert = UIAlertController(title: title , message: nil , preferredStyle: UIAlertControllerStyle.alert)
            value.present(alert, animated: true, completion: nil)
        if !networkAvailability(){
                DispatchQueue.main.async {
                    alertNetworkNotAvailableTryAgain(controller: value)
                }
            }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.06))
    }
}

func showLoadingAlertWithProgressbar(_ title : String, networkIndicator network : Bool, additionalButton  btnTitle : String?)
{
    stopSpinner()
    if UIApplication.topViewController() != nil
    {
        stopSpinner()
        if network
        {
            NetworkActivityIndicatorManager.start()
        }
       let alert = UIAlertController(title: "\(title)\n" , message: nil , preferredStyle: UIAlertControllerStyle.alert)
            
            progressView = UIProgressView.init(progressViewStyle: .default)
            progressView?.frame = CGRect.init(x: 0, y: 0, width: 250, height: 15)
            progressView?.center = CGPoint.init(x: 136.5, y: 60.0)
            progressView?.progress = 0.0

            alert.view.addSubview(progressView!)
            
            if btnTitle != nil
            {
                let btn = UIAlertAction.init(title: btnTitle, style: .default, handler: { (UIAlertAction) in
                    if  FOLDER_ID.length>0
                    {
                        dataTask?.cancel()
                        var outboundRecordArr : [Outbound_messages]?  = []
                        outboundRecordArr = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(FOLDER_ID)!)
                        
                        outboundRecordArr?[0].fax_status = Int64(FAX_STATUS.PAID_UNSENT.rawValue)
                        DataModel.sharedInstance.saveContext()
                        hideLoadingAlert()
                    }
                    else if UrlPath != nil
                    {
                        progressView = nil
                        dataTask?.cancel()
//                        DLog("UrlPath : =  \(UrlPath)")
                        WizardViewController().deleteFaxAttachment(url: UrlPath)
                        hideLoadingAlert()
                        UrlPath = nil
                    }
                })
                alert.addAction(btn)
            }
            hideLoadingAlertWithPresentController(viewcontroller: alert)
    }
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
}

func hideLoadingAlert()
{
    stopSpinner()
  
    if let value = UIApplication.topViewController()
    {
        if value is UIAlertController 
        {
            NetworkActivityIndicatorManager.stop()
            value.dismiss(animated: true, completion: {ForceSTopIndicator()})
//            DLog("\(#line)")
        }
    }
}

func hideLoadingAlertWithComplition(_ callback: @escaping () -> Void)
{
    stopSpinner()
    ForceSTopIndicator()
    if let value = UIApplication.topViewController()
    {
        if value is UIAlertController
        {
            NetworkActivityIndicatorManager.stop()

            value.dismiss(animated: true, completion: {
//            DLog("\(#line)")
                callback()
            })
        }
        else
        {
            callback()
        }
    }
    else
    {
        callback()
    }
}

func hideLoadingAlertWithPresentController(viewcontroller:UIViewController) {
    stopSpinner()
    
    DispatchQueue.main.async {
        if let value = UIApplication.topViewController()
        {
            if value is UIAlertController
            {
                NetworkActivityIndicatorManager.stop()
                //            DLog("\(#line)")
                value.dismiss(animated: true, completion: {
                    UIApplication.topViewController()!.present(viewcontroller, animated: true, completion: nil)
                })
            }
            else
            {
                UIApplication.topViewController()!.present(viewcontroller, animated: true, completion: nil)
            }
        }
        else
        {
            UIApplication.topViewController()!.present(viewcontroller, animated: true, completion: nil)
        }
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
}

func startSpinner(type:Int,message:String,networkIndicator:Bool,color: UIColor)
{
    UIApplication.shared.beginIgnoringInteractionEvents()
    if let value = UIApplication.topViewController()
    {
//        stopSpinner()
        if value is UIAlertController
        {
            return
        }
        if value is GetCreditViewController
        {
            homeVC?.enabeDisableBarButton(bool: true)
        }
    }
    ActivityIndicator().StartActivityIndicator(type:type, message: message, netWorkIndicator:networkIndicator,color: color)
}

func stopSpinner()
{
    DispatchQueue.main.async {
        NetworkActivityIndicatorManager.stop()
        if let value = UIApplication.topViewController()
        {
            value.view.isUserInteractionEnabled =  true
        }
        ActivityIndicator().StopActivityIndicator()
        if indicator != nil
        {
            indicator.stopAnimating()
        }
        if let value1 = UIApplication.topViewController()
        {
            if value1 is FaxNumberViewController
            {
                let faxVC = value1 as! FaxNumberViewController
                faxVC.enabeDisableBarButton(bool: true)
                faxVC.pickerView.isUserInteractionEnabled = true
                faxVC.countryView.isUserInteractionEnabled = true
                faxVC.indicatorLayer.isHidden = true
                
            }
            if value1 is HomeViewController
            {
                homeVC?.enabeDisableBarButton(bool: true)
                
            }
        }
    }
}

func delay(delay:Double, closure:@escaping ()->())
{
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(Double(NSEC_PER_SEC)))) / Double(NSEC_PER_SEC), execute: closure)
}
//MARK: Get all the Files from Particualer Directory
func getFilesFromURL(url : URL) -> [URL]
{
    do {
        // Get the directory contents urls (including subfolders urls)
        let directoryContents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
//        DLog("directoryContents : \(directoryContents)")
        return directoryContents

    } catch let error as NSError {
        DLog(error.localizedDescription)
        return []
    }
}

func validDropDocument(_ fileName : String) -> Bool// Supported file for interfax: DOC, DOCX, PDF, TIF, TXT, XLS, XLSX, PPT, PPTX, GIF, PNG, JPG, JPEG, RTF, BMP, TIFF
{
    let arrTypes = NSMutableArray()
    arrTypes.add(".DOC")
    arrTypes.add(".DOCX")
    arrTypes.add(".PDF")
    arrTypes.add(".TIF")
    arrTypes.add(".TXT")
    arrTypes.add(".XLS")
    arrTypes.add(".XLSX")
    arrTypes.add(".PPT")
    arrTypes.add(".PPTX")
    arrTypes.add(".GIF")
    arrTypes.add(".PNG")
    arrTypes.add(".JPG")
    arrTypes.add(".JPEG")
    arrTypes.add(".RTF")
    arrTypes.add(".BMP")
    arrTypes.add(".TIFF")
    return (supportsFile(fileName: fileName, fromExt: arrTypes as [AnyObject]))
}

func IsFileSupportWithVitelityAPI(_ fileName : String) -> Bool// Vitelity API suppoeted file: TXT, DOC, DOCX, PDF, XLS, XLSX, RTF, TIF, TIFF, JPEG, JPG, PNG, BMP
{
    let arrTypes = NSMutableArray()
    arrTypes.add(".TXT")
    arrTypes.add(".DOC")
    arrTypes.add(".DOCX")
    arrTypes.add(".PDF")
    arrTypes.add(".XLS")
    arrTypes.add(".XLSX")
    arrTypes.add(".XLSX")
    arrTypes.add(".RTF")
    arrTypes.add(".TIF")
    arrTypes.add(".TIFF")
    arrTypes.add(".JPEG")
    arrTypes.add(".JPG")
    arrTypes.add(".PNG")
    arrTypes.add(".BMP")
    return (supportsFile(fileName: fileName, fromExt: arrTypes as [AnyObject]))
}

func localServerAllowedFileExtensions() -> [String]{
    var arrTypes:[String] = []
    arrTypes.append("doc")
    arrTypes.append("docx")
    arrTypes.append("pdf")
    arrTypes.append("tif")
    arrTypes.append("txt")
    arrTypes.append("xls")
    arrTypes.append("xlsx")
    arrTypes.append("ppt")
    arrTypes.append("pptx")
    arrTypes.append("gif")
    arrTypes.append("png")
    arrTypes.append("jpg")
    arrTypes.append("jpeg")
    arrTypes.append("rtf")
    arrTypes.append("bmp")
    arrTypes.append("tiff")
    return arrTypes
}

func setStatusBar(_ red : CGFloat, green : CGFloat, blue : CGFloat, alpha : CGFloat, statusBarStyle : UIStatusBarStyle, view : UIView)
{
    UIApplication.shared.statusBarStyle = statusBarStyle

    let view1 = UIView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 20.0)
    )
    view1.backgroundColor = UIColor(red: red / 255.0 , green: green / 255.0, blue: blue / 255.0, alpha: alpha)

    view.addSubview(view1)
}

func SupportedImageTypeArr() -> NSArray
{
    let arrTypes = NSMutableArray()
    arrTypes.add(".tif")
    arrTypes.add(".tiff")
    arrTypes.add(".jpeg")
    arrTypes.add(".jpg")
    arrTypes.add(".png")
    arrTypes.add(".bmp")
    return arrTypes
}

func SupportedLogoImageTypeArr() -> NSArray
{
    let arrTypes = NSMutableArray()
    arrTypes.add(".jpeg")
    arrTypes.add(".jpg")
    arrTypes.add(".png")
    arrTypes.add(".bmp")
    return arrTypes
}

func CreateDir(DirName : String) -> URL
{
    var isDir : ObjCBool = false
    let documentsPath = getOutgoingPath()
//    DLog("documentsPath: \(documentsPath)")
    let logsPath = documentsPath?.appendingPathComponent(DirName)
    do
    {
        if FileManager.default.fileExists(atPath:(logsPath?.path)!, isDirectory:&isDir)
        {
        }
        else
        {
            try FileManager.default.createDirectory(atPath : (logsPath?.path)!, withIntermediateDirectories:  true, attributes: nil)
        }
    }
    catch let error as NSError
    {
//        DLog("Unable to create directory \(error.debugDescription)")

    }
    return logsPath!
}



//MARK: Convert Image into PDF

func PDFFromImage(_ image : UIImage, imageName : String, path : URL) -> URL {
    
    let rect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let pdfPath = path.appendingPathComponent("\(imageName)1.pdf")
//    DLog("pdfpath: \(pdfPath)")
    UIGraphicsBeginPDFContextToFile(pdfPath.path, CGRect.zero, nil)
    UIGraphicsBeginPDFPageWithInfo(rect, nil)
//    var currentContext:CGContext = UIGraphicsGetCurrentContext()!
    image.draw(in: rect)
    UIGraphicsEndPDFContext()
    return pdfPath
}

func imageFromPDF(url: URL, targetSize:CGSize ,PageNo : Int) -> UIImage? {

    if  let pdfRef:CGPDFDocument = CGPDFDocument(url as CFURL)
    {
            let noOF_Page : Int? = pdfRef.numberOfPages
            UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
            if noOF_Page! >=  PageNo
            {
                if let pageRef:CGPDFPage = pdfRef.page(at: PageNo)
                {
                    drawPDFPageInRect(pageRef: pageRef, destinationRect:CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
                    let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                    return image
                }
        }
    }
    return nil
}

func drawPDFPageInRect(pageRef:CGPDFPage, destinationRect:CGRect) {
    let context = UIGraphicsGetCurrentContext()
    if context == nil {
//        DLog("Error: No context to draw to")
        return
    }
    context!.saveGState()
    let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!

    var transform:CGAffineTransform = CGAffineTransform.identity

    transform = transform.scaledBy(x: 1.0, y: -1.0)
    transform = transform.translatedBy(x: 0.0, y: -image.size.height)
//    context!.concatCTM(transform)
    context?.concatenate(transform)
    let destRect:CGRect = destinationRect.applying(transform)
    let pageRect:CGRect = pageRef.getBoxRect(.cropBox)
    let drawingAspect:CGFloat = aspectScaleFit(sourceSize: pageRect.size, destRect: destRect)
    let drawingRect:CGRect = rectByFittingRect(sourceRect: pageRect, destinationRect: destRect)

    context!.translateBy(x: drawingRect.origin.x, y: drawingRect.origin.y)
    context!.scaleBy(x: drawingAspect, y: drawingAspect)
    context!.drawPDFPage(pageRef)
    context!.restoreGState()
}

func aspectScaleFit(sourceSize:CGSize, destRect:CGRect) -> CGFloat {
    let destSize:CGSize = destRect.size
    let scaleW:CGFloat = destSize.width // sourceSize.width
    let scaleH:CGFloat = destSize.height / sourceSize.height
    return fmin(scaleW, scaleH)
}

func rectByFittingRect(sourceRect:CGRect, destinationRect:CGRect) -> CGRect {
    let aspect:CGFloat = aspectScaleFit(sourceSize: sourceRect.size, destRect: destinationRect)
    let targetSize:CGSize = CGSize(width : sourceRect.size.width * aspect, height: sourceRect.size.height * aspect)
    let center:CGPoint = CGPoint(x:destinationRect.midX,y: destinationRect.midY)
    return rectAroundCenter(center: center, size: targetSize)
}

func rectAroundCenter(center:CGPoint, size:CGSize) -> CGRect {
    let halfWidth:CGFloat = size.width / 2.0
    let halfHeigth:CGFloat = size.height / 2.0

    return CGRect(x: center.x - halfWidth, y: center.y - halfHeigth, width : size.width, height: size.height)
}

func getPathURLOfContainer() -> URL?{
    var url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WIDGET_EXTN_GROUP_NAME)
    url = url?.appendingPathComponent("Library")
    return url
}

func getOutgoingPath() -> URL?
{
    //DLog("name" , String(outboundEntity!.folder_id))
    var isDir : ObjCBool = false
    let documentsPath = getPathURLOfContainer()
//    DLog("documentsPath: \(documentsPath)")
    let logsPath = documentsPath?.appendingPathComponent("OutBound")
    do
    {
        if FileManager.default.fileExists(atPath:(logsPath?.path)!, isDirectory:&isDir)
        {
            return logsPath
        }
        else
        {
            try FileManager.default.createDirectory(atPath : (logsPath?.path)!, withIntermediateDirectories:  true, attributes: nil)
        }
        
    }
    catch let error as NSError
    {
//        DLog("Unable to create directory \(error.debugDescription)")
        
    }
    return logsPath
}

func getIncomingPath() -> URL?
{
    var isDir : ObjCBool = false
    let documentsPath = getPathURLOfContainer()
    let logsPath = documentsPath?.appendingPathComponent("InBound")
    do
    {
        if FileManager.default.fileExists(atPath:(logsPath?.path)!, isDirectory:&isDir)
        {
            return logsPath
        }
        else
        {
            try FileManager.default.createDirectory(atPath : (logsPath?.path)!, withIntermediateDirectories:  true, attributes: nil)
        }
    }
    catch let error as NSError
    {
//        DLog("Unable to create directory \(error.debugDescription)")
    }
    return logsPath
}

func CurrentDevice()
{

    if (UIScreen.main.bounds.size.height == 568)
    {
        isForiPhone5 = true;
        isForiPhone6 = false;
    }
    else if (UIScreen.main.bounds.size.height == 667 || UIScreen.main.bounds.size.height == 736 || UIScreen.main.bounds.size.height == 414 || UIScreen.main.bounds.size.height == 335 )
    {

        isForiPhone5 = false;
        isForiPhone6 = true;
    }
    else
    {
        isForiPhone5 = false;
        isForiPhone6 = false;

    }
    /*****************For iPhone 6 ***************/
    if (UIScreen.main.bounds.size.height == 667)
    {
        isForiPhone6 = true;
    }
    else
    {
        isForiPhone6 = false;
    }/*****************For iPhone 6+ ***************/
    if (UIScreen.main.bounds.size.height == 736 || UIScreen.main.bounds.size.width == 414)
    {
        isForiPhone6Plus = true;
        isForiPhone6 = false;
    }
    else
    {
        isForiPhone6Plus = false;
    }
    
    if (UIScreen.main.bounds.size.height > 736)
    {
        isThisForiPad = true
    }
    else
    {
        isThisForiPad = false
    }
}

//MARK: NSDate Convert Methods
func convertStringToDate(dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy"

    guard let date = dateFormatter.date(from: dateString) else {
//        DLog("no date from string")
        return nil
    }
    //let value = dateFormatter.date(from: dateString)!
    return date
}

func convertStringToTime(timeString: String) -> Date? {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm:ss"

    guard let time = timeFormatter.date(from: timeString) else {
//        DLog("no time from string")
        return nil
    }
    //let value = timeFormatter.date(from: timeString)!
    return time
}

//MARK : Email Validation

func isValidEmail(testStr:String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: testStr)
}

//MARK: Create PDF from rtf and txt Files

func createPDF(fileURL : URL, data : Data , fileType : String , fromAction: String)
{
    do{
        var pageRect : CGRect = CGRect(x: 0, y: 0,width:  670,height:  800)
        let url : CFURL = fileURL as CFURL
        
        var keyCallbacks = kCFTypeDictionaryKeyCallBacks
        var valueCallbacks = kCFTypeDictionaryValueCallBacks
        
        let myDictionary : CFMutableDictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks,&valueCallbacks)
        
        let pdfContext = CGContext (url, mediaBox: &pageRect, myDictionary)
        
        
        ////////Insert text //////
        
        let txtView = UITextView(frame: CGRect(x: 0, y: 0, width: 540, height: 740))
        
        if fileType == "txt" || fileType == "TXT"
        {
            
            let plainString = try NSAttributedString(data: data, options:[:], documentAttributes: nil)
            txtView.attributedText = plainString
        }
        else if fileType == "rtf" || fileType == "RTF"
        {
//            DLog("data of rtf: \(data)")
            
            if fromAction == "writetext"
            {
                if let  atr : NSAttributedString =  NSKeyedUnarchiver.unarchiveObject(with: data) as? NSAttributedString
                {
                    txtView.attributedText = atr
//                    DLog("data of rtf: \(atr ) and  === \(txtView.text)")
                }
            }
            else
            {
                let attr = [NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType, NSWritingDirectionAttributeName : [ NSWritingDirection.leftToRight.rawValue | NSTextWritingDirection.override.rawValue ]] as [String : Any]
                // Here we have convert rtf and txt file data to AttributedString
                do{
                    let plainString = try NSAttributedString(data: data, options: attr as [String : AnyObject], documentAttributes: nil)
                    txtView.attributedText = plainString
                }
                catch{}
            }
//
        }
        else
        {
            let plainString = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
            txtView.attributedText = plainString
        }
        
        pdfContext?.beginPage (mediaBox: &pageRect)
        UIGraphicsPushContext(pdfContext!)
        UIGraphicsGetCurrentContext()
        let  atrs : NSAttributedString
//        let atr  = txtView.attributedText!
        if fromAction == "writetext"
        {
             atrs  =  NSKeyedUnarchiver.unarchiveObject(with: data) as! NSAttributedString
        }
        else
        {
            atrs = txtView.attributedText
        }
//        var range = NSMakeRange(0, txtView.text.characters.count)
//        let  attribute  =   atr.attributes(at: 0, effectiveRange: &range)
//        
//        let currentText : CFAttributedString? = CFAttributedStringCreate(nil, atr as! CFString, nil)
//            CFAttributedStringCreate(nil, txtView.text as CFString, attributes as CFDictionary!)
//        if currentText != nil {
        
            let framesetter : CTFramesetter? = CTFramesetterCreateWithAttributedString(atrs)
            
            if framesetter != nil {
                // Create the PDF context using the default page size of 612 x 792.
                UIGraphicsBeginPDFContextToFile((fileURL.path), CGRect.zero, nil)
                var currentRange : CFRange = CFRangeMake(0, 0)
                var currentPage = 0
                var done = false
                
                repeat {
                    // Mark the beginning of a new page.
                    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: 612, height: 792), nil)
                    
                    // Draw a page number at the bottom of each page.
                    currentPage += 1
                    
                    // Render the current page and update the current range to
                    // point to the beginning of the next page.
                    
                    currentRange = renderPage(currentPage, withTextRange: currentRange, andFramesetter: framesetter!)
                    
                    // If we're at the end of the text, exit the loop.
                    
                    if (currentRange.location == CFAttributedStringGetLength(atrs as CFAttributedString))
                    {
                        done = true
                    }
                } while(done == false);
                
                // Close the PDF context and write the contents out.
                UIGraphicsEndPDFContext();
                
            }
            else {
//                DLog("Could not create the framesetter needed to lay out the atrributed string.")
            }
//        }
    } catch {}
}

// Use Core Text to draw the text in a frame on the page.

func renderPage(_ pageNum: Int, withTextRange currentRange: CFRange, andFramesetter framesetter: CTFramesetter) -> CFRange {
    var currentRange = currentRange
    // Get the graphics context.
    let currentContext : CGContext = UIGraphicsGetCurrentContext()!
    
    // Put the text matrix into a known state. This ensures
    // that no old scaling factors are left in place.
    currentContext.textMatrix = CGAffineTransform.identity
    
    // Create a path object to enclose the text. Use 72 point
    // margins all around the text.
    let frameRect = CGRect(x: 72, y: 72, width: 468, height: 648)
    let framePath: CGMutablePath = CGMutablePath()
    framePath.addRect(frameRect)
    
    // Get the frame that will do the rendering.
    // The currentRange variable specifies only the starting point. The framesetter
    // lays out as much text as will fit into the frame.
    let frameRef : CTFrame = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)

    // Core Text draws from the bottom-left corner up, so flip
    // the current transform prior to drawing.
    currentContext.translateBy(x: 0, y: 792);
    currentContext.scaleBy(x: 1.0, y: -1.0);
    
    // Draw the frame.
    CTFrameDraw(frameRef, currentContext);
    
    // Update the current range based on what was drawn.
    currentRange = CTFrameGetVisibleStringRange(frameRef);
    currentRange.location += currentRange.length;
    currentRange.length = 0;
    
    return currentRange;
    
}

//MARK: Delete Prticular File

func deleteFile(fileUrl : URL) ->Bool
{
    if FileManager.default.fileExists(atPath: (fileUrl.path)) {
        do
        {
            try FileManager.default.removeItem(atPath: (fileUrl.path))
            
        }
        catch let error as NSError
        {
            DLog(error.debugDescription)
        }
        return true
    }
    else{
        return false
    }
}

//MARK: Count Particaular PDF Pages
func pdfPages(fileUrl: URL) -> Int
{
    var documentRef:CGPDFDocument!
    var noOF_Page : Int!
    if FileManager.default.fileExists(atPath: (fileUrl.path))
    {
        documentRef = CGPDFDocument(fileUrl as CFURL)
        noOF_Page = documentRef.numberOfPages
        return noOF_Page
    }
    else
    {
        return 0
    }
}

//MARK: Count Total Attachmnets Pages
func getTotalPDFpages(folder_Id : Int64 ) -> Int64
{
    let path = getOutgoingPath()?.appendingPathComponent(String(folder_Id))
    let totalContents = getFilesFromURL(url : path!)
//     DLog("totalContents = \(totalContents)")
    // By default 1 coverpage so initialize by 1.
    
//    let cover = totalContents.contains((getOutgoingPath()?.appendingPathComponent(String(folder_Id)).appendingPathComponent("cover"))!)
//    print(totalContents.index(of: (getOutgoingPath()?.appendingPathComponent(String(folder_Id)).appendingPathComponent("cover"))!))
    
    var total_Pages : Int64 = 1
    for i in 0..<totalContents.count
    {
        let pathExtention = totalContents[i].pathExtension
        if pathExtention != ""{
            
            
            if pathExtention.lowercased() == "pdf"
            {
                if let documentRef =  CGPDFDocument(totalContents[i] as CFURL)
                {
                    let noOF_Page : Int! = documentRef.numberOfPages
                    total_Pages  = total_Pages + noOF_Page
                }
            }
            else{
                total_Pages = total_Pages + 1
            }
        }
    }

//    DLog("total_Pages = \(total_Pages)")
    return total_Pages
}

func ValidateEmail(email: String) -> Bool {
    let emailReg = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,8}"
    let emailTest = NSPredicate(format: "SELF MATCHES %@", emailReg)
    if emailTest.evaluate(with: email) != true
    {
        return false
    }
    else {
        return true
    }
}

func alertview(title: String ,message : String ,  _ viewContriller : UIViewController)
{
    DispatchQueue.main.async {
        ForceSTopIndicator()
        let alert = UIAlertController(title: title , message: message , preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: OK_BTN, style: .default) { action in
            if let value = UIApplication.topViewController(){
                stopSpinner()
                if value is HomeViewController
                {
                    let homeVC = value as! HomeViewController
                    homeVC.faxNumberBtton_Update()
                    homeVC.getCreditUIUpdate()
                }
                else if value is SettingsViewController
                {
                    let settingVC = value as! SettingsViewController
                    settingVC.deviceCount = 0
                    settingVC.reloadTable()
                }
            }
        }
       
        alert.addAction(ok)
        
        hideLoadingAlertWithPresentController(viewcontroller: alert)
//        viewContriller.present(alert, animated: true, completion: nil)
    }
}

func alertviewwithCompletion(title: String ,message : String ,  _ viewContriller : UIViewController,completion:@escaping () -> Void)
{
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title , message: message , preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: OK_BTN, style: .default) { action in
            if let value = UIApplication.topViewController(){
                
                if value is HomeViewController
                {
                    let homeVC = value as! HomeViewController
                    homeVC.faxNumberBtton_Update()
                    homeVC.getCreditUIUpdate()
                }
                else if value is SettingsViewController
                {
                    let settingVC = value as! SettingsViewController
                    settingVC.deviceCount = 0
                    settingVC.reloadTable()
                }
                completion()
            }
        }
        
        alert.addAction(ok)
        hideLoadingAlertWithPresentController(viewcontroller: alert)
    }
}

func alertviewForLogoutComplete(title: String ,message : String ,  _ viewContriller : UIViewController)
{
    DispatchQueue.main.async {
        ForceSTopIndicator()
        DataModel.sharedInstance.removeAllInBoundDataFromDatabase()
        let alert = UIAlertController(title: title , message: message , preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: OK_BTN, style: .default) { action in
            if let value = UIApplication.topViewController(){
                
                getUserFaxNumbers()
                AppDelegate().getFax()
                if value is HomeViewController
                {
                    let homeVC = value as! HomeViewController
                    homeVC.inboundList = []
                    homeVC.faxNumberBtton_Update()
                    homeVC.getCreditUIUpdate()
                }
                else if value is SettingsViewController
                {
                    let settingVC = value as! SettingsViewController
                    settingVC.deviceCount = 0
                    settingVC.reloadTable()
                }
                else if value is UIViewController
                {
                    if UIApplication.shared.keyWindow?.rootViewController as? UITabBarController != nil
                    {
                        let tababarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
                        tababarController?.selectedIndex = 0
                    }
                    UIApplication.topViewController()?.dismiss(animated: true, completion: {
                        _ = UIApplication.topViewController()?.navigationController?.popToViewController(homeVC!, animated: true)
                    })
                }
                ForceSTopIndicator()
            }
        }
        alert.addAction(ok)
        hideLoadingAlertWithPresentController(viewcontroller: alert)
    }
}


func md5(string: String) -> String {
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    if let data = string.data(using: String.Encoding.utf8) {
        data.withUnsafeBytes { bytes in
            CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
    }
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
}
func getCurrentCountryCode() -> String
{
    var languageCode = ""
    let currentLocale:Locale = NSLocale.autoupdatingCurrent
    if let langCode = currentLocale.regionCode{
        languageCode = langCode
    }
    return languageCode
}
func getCurrentLanguageCode() -> String
{
    var languageCode = ""
    let currentLocale:Locale = NSLocale.autoupdatingCurrent
    if let langCode = currentLocale.languageCode{
        languageCode = langCode
    }
    return languageCode
}

func isUserLogin() -> Bool{
    var status = false
    if let value = getValueFromUserDefault(key: DEFAULT_USERLOGIEDIN) as? Int{
        if value == 1{
            status = true
        }
    }
    return status
}

//MARK:- Reachability
func networkAvailability() -> Bool
{
    if Reachabilitys.internetAvaibility() == false
    {
       DispatchQueue.main.async {
            statusBarNotification.shoew(message: "No Internet Connection", color: UIColor(red: 255/255, green: 99/255, blue: 71/255, alpha: 1.0), lightStatusBar: true)
            statusBarNotification.show()
        }
    }
    return  Reachabilitys.internetAvaibility()
}



func alertNetworkNotAvailableTryAgain(controller:UIViewController)
{
    stopSpinner()
    ForceSTopIndicator()
    if let val  = UIApplication.topViewController()
    {
        if val is UIAlertController
        {
            let vu = val as! UIAlertController
            if vu.message == PLEASE_CHECK_INTERNET_CONN
            {
                return
            }
        }
    }
    //alertview(title: OOPS_TITLE, message: PLEASE_CHECK_INTERNET_CONN, controller)
}

//MARK:- Web service calling
func addUserCredit(status:String){
    if !networkAvailability()
    {
        if let value = UIApplication.topViewController()
            
        {
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SEND_PAYMENT_DATA_TO_SERVER])

    var dict = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    dict = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.CREDIT.rawValue) 
    dict.setValue("1", forKey: "debug")
    dict.setValue(status, forKey: "local_receipt_status")
    user_id = user_id?.appending(AUTH_KEY_IFAX.md5!)
    do
    {   
        let jsonStr = NSString.init(data: try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted), encoding: String.Encoding.utf8.rawValue)
        let params = String(format:"Data=[%@]&unique_id=%@",jsonStr!,(user_id?.md5!)!)
        let reqDict = NSMutableDictionary()
        reqDict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        reqDict.setValue(ADD_USER_CREDIT, forKey: "url")
        if let data = AppDelegate().sendSynchronousRequestWithParameters(reqDict, andPostData: params.data(using: .utf8) as NSData?)
        {
            if data != nil
            {
                let res = NSString.init(data: data as Data, encoding: String.Encoding.utf8.rawValue)
                DLog("Added Credit = \(res)")
                
                let responseDictData = try! JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                if let result = responseDictData.value(forKey: "data")
                {
                    let result_data : NSArray! = result as! NSArray
                    stopSpinner()
                    let status : String = responseDictData.value(forKey: "status") as! String
                    if status == "1"
                    {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: GET_CREDIT_NOTIFIED), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: CREDIT_SETTING_NOTIFIED), object: nil)

                        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:CREDIT_ADDED])

                        let total_credits = ((result_data.object(at: 0) as! NSDictionary).value(forKey: "credits") as! Int)
                        setValueInUserDefault(key: DEFAULT_CREDIT_COUNT, value:  total_credits, isSync: true)
                        
                        var buyCreditSuccess = BUY_CREDIT_SUCCESS_ALERT
                        
                        buyCreditSuccess = buyCreditSuccess.replacingOccurrences(of: "%@", with: "\((result_data.object(at: 0) as! NSDictionary).value(forKey: "newly_added_credits") as! Int)")
                        
                        
                        let alertController = UIAlertController.init(title: PURCHASE_SUCCESS_TITLE, message: buyCreditSuccess, preferredStyle: .alert)
                        let btn = UIAlertAction.init(title: OK_BTN, style: .default, handler: { (UIAlertAction) in
                            hideLoadingAlertWithComplition {
                                UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
                            }
                        })
                        alertController.addAction(btn)
                        hideLoadingAlertWithPresentController(viewcontroller: alertController)
                        
                    }
                    else
                    {
                        hideLoadingAlertWithComplition {
                            if let msg : String = responseDictData.value(forKey: "message") as? String
                            {
                                alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                                //alertview(title: OOPS_TITLE, message: msg, UIApplication.topViewController()!)
                            }
                            else
                            {
                                alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
                            }
                            
                        }
                        //            hideLoadingAlert()
                    }
                    //                DLog("Response of Add Credits \(responseDictData)")
                    stopSpinner()
                }
            }
        }
    }
    catch
    {
//        DLog("\(String(#line))...Something wrong")
        hideLoadingAlertWithComplition {
            alertview(title: TITLE_PURCHASE_UNSUCCESS, message: CONTACT_SUPPORT_TEAM1, wizardController!)
        }
    }
}

func GetOutboundCountryList()
{
    if !networkAvailability()
    {
        DispatchQueue.main.async {
        if let value = UIApplication.topViewController()
        {
                if  isTapNewFaxButton == true
                {
                    goToWizardScreen()
                }
                else
                {
                    alertNetworkNotAvailableTryAgain(controller: value)
                }
            }
        }
        stopSpinner()
        return
    }

    //Create an URLRequest & Create POST Params and add it to HTTPBody
    
    var user_id = ""
    if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    {
        user_id = value
    }
    let params = "user_id=\(user_id)&device_id=\(device_id)"
    let dict = NSMutableDictionary()
    dict.setValue(OUTBOUND_PRICE_LIST_URL, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict,andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    
    if data != nil
    {
        do
        {
            if let OutboundCountryListArr = try JSONSerialization.jsonObject(with: data as! Data, options: .mutableContainers) as? NSMutableArray
            {
                if OutboundCountryListArr.count > 0
                {
                    UserDefaults.standard.set(OutboundCountryListArr, forKey: OUTBOUND_FAX_COUNTRY_LIST)
                    
                    
                    // Outbound country list
                    var syncObjectArr = DataModel.sharedInstance.fetchServerSyncData() as [Last_sync_detail]
                    if syncObjectArr.count > 0
                    {
                        let syncObject  = syncObjectArr[0]
                        let outbound_price_server_date =  syncObject.outbound_price_server_date
                        if (outbound_price_server_date != nil)
                        {
                            syncObject.outbound_price_local_date = outbound_price_server_date
                            DataModel.sharedInstance.saveContext()
                        }
                    }
                    
                    countryList = OutboundCountryListArr //Var used is modified in number purchase screen
                    outBoundCountryList = OutboundCountryListArr //Var not modified.
                    let locale = NSLocale.current.regionCode
                    let filteredData2: NSArray = countryList.filtered(using: NSPredicate(format: "self.%@ contains[c] %@", "TerritoryCode", "\(locale!)")) as NSArray
                    if filteredData2.count > 0
                    {
                        selectedCountry = filteredData2[0] as! NSMutableDictionary
                    }
                    if  isTapNewFaxButton == true
                    {
                        DispatchQueue.main.sync {
                            goToWizardScreen()
                        }
                    }
                }
                else
                {
                    if isTapNewFaxButton == true
                    {
                        DispatchQueue.main.sync {
                            goToWizardScreen()
                        }
                    }
                }
            }else
            {
                if let value = UIApplication.topViewController()
                {
                        DispatchQueue.main.async {
                        alertNetworkNotAvailableTryAgain(controller: value)
                    }
                }
            }
        }
        catch
        {
            if isTapNewFaxButton == true
            {
                DispatchQueue.main.sync {
                    goToWizardScreen()
                }
            }
//            DLog("json error: \(error)")
            let passCodeDefault = UserDefaults.standard.object(forKey: PASSCODE_ENABLE)
            if passCodeDefault == nil
            {
                if let value = UIApplication.topViewController(){
                    DispatchQueue.main.async {
                        alertNetworkNotAvailableTryAgain(controller: value)
                    }
                }
            }
        }
    }
    else
    {
        if  isTapNewFaxButton == true
        {
            DispatchQueue.main.sync {
                goToWizardScreen()
            }
        }
    }
    dict.removeAllObjects()
    DispatchQueue.main.async {
        stopSpinner()
    }
}

func checkStatusOfFaxes(faxStatus :  Array<Int>)  // faxStatus will be one of them "FAX_STATUS" (check enum)
{
        if  isCheckingFaxStatus == false
        {
            isCheckingFaxStatus = true
            var outboundFailedFaxes : [Outbound_messages] = []
            outboundFailedFaxes  = DataModel.sharedInstance.fetchOutboundFaxesForFaxStatus(fax_status: faxStatus)
            
            var paramValues = ""
//             DLog("paramValues....")
            for i in 0..<outboundFailedFaxes.count
            {
                let server_id = String(outboundFailedFaxes[i].server_id)
                server_ID = server_id
                if i < outboundFailedFaxes.count-1
                {
                    paramValues = paramValues + server_id + ","
                }
                else
                {
                    paramValues = paramValues + server_id
                }
            }
//             DLog("paramValues....")
            
            if paramValues != ""
            {
                isFaxStatusCountOne = false
                if faxStatus.count == 1
                {
                    isFaxStatusCountOne = true
                }
//                 DLog("checkStatusOfSendingFax....")
                 checkStatusOfSendingFax(server_ids: paramValues)
            }
            else
            {
                isCheckingFaxStatus = false
            }
            
        }
        else
        {
//            DLog("Checking status continue...")
        }
}

func handleStatusOfFaxes(dataArr : NSDictionary)
{
    DLog("Fax status...\(dataArr)")
    if let dataArr = dataArr.value(forKey: "data") as! NSArray?
    {
        for data in dataArr
        {
            let dict:NSDictionary =  data as! NSDictionary
            
            var outboundRecordArr : [Outbound_messages]?  = []
            let server_id = (((dict as AnyObject).value(forKey: "server_id") as? String)!)
            server_ID = server_id
//            DLog("server id: \(server_id)")
            outboundRecordArr  = DataModel.sharedInstance.fetchOutboundForServerId(Int64(server_id)!)
            
            if  (outboundRecordArr != nil && outboundRecordArr!.count > 0)
            {
                let outboundRecord : Outbound_messages? = outboundRecordArr?[0]
                let fax_status : Int
                
                if let status = dict.value(forKey: "status")
                {
                    if String(describing: status) == "1" || String(describing: status) != "-3"
                    {
                        /***** Update data *****/
                        
                        // completion_time
                        if var completion_time = (dict as AnyObject).value(forKey: "completion_time") as? String
                        {
                            if completion_time != ""{
                                var myString = completion_time
                                let plusRange: Range<String.Index> = myString.range(of: ":")!
                                let firstCharacter: Int = myString.distance(from: myString.startIndex, to: plusRange.lowerBound)
                                myString = myString.insert(string: ",", ind: firstCharacter - 3)
                                completion_time = myString
                                outboundRecord?.completion_time = completion_time
                            }
                        }
                        
                        if isFaxStatusCountOne == true
                        {
                            // Date
                            outboundRecord?.date = NSDate()
                        }
                        
                        // duration
                        if let duration = (dict as AnyObject).value(forKey: "duration") as? String
                        {
                            if duration != ""
                            {
                                outboundRecord?.duration = Int64(duration)!
                            }
                        }
                        
                        // fax_api
                        if let fax_api = (dict as AnyObject).value(forKey: "fax_api") as? String
                        {
                            if fax_api != ""
                            {
                                outboundRecord?.fax_api = Int64(fax_api)!
                            }
                        }
                        
                        // completion_time
                        if var submit_time = (dict as AnyObject).value(forKey: "submit_time") as? String
                        {
                            DLog(submit_time)
                            if submit_time != ""{
                                var myString = submit_time
                                let plusRange: Range<String.Index> = myString.range(of: ":")!
                                let firstCharacter: Int = myString.distance(from: myString.startIndex, to: plusRange.lowerBound)
                                myString = myString.insert(string: ",", ind: firstCharacter - 3)
                                submit_time = myString
                                outboundRecord?.submit_time = submit_time
                            }
                        }
                        
                        // transaction_id
                        if let transaction_id = (dict as AnyObject).value(forKey: "tranction_id") as? String
                        {
                            if transaction_id != ""{
                                outboundRecord?.transaction_id = Int64(transaction_id)!
                            }
                        }
                    }
                    
                    if String(describing: status) == "1"
                    {
                        fax_status = FAX_STATUS.RECEIVED_FAX.rawValue
                        // transaction_id
                        if let transaction_id = (dict as AnyObject).value(forKey: "tranction_id") as? String
                        {
                            if transaction_id != ""
                            {
                                outboundRecord?.transaction_id = Int64(transaction_id)!
                                outboundRecord?.fax_status = Int64(fax_status)
                                
                                DataModel.sharedInstance.saveContext()
                                DispatchQueue.main.async {
                                    if homeVC != nil
                                    {
                                       homeVC?.fetchOutboundFaxList()
                                    }
                                    else
                                    {
                                       HomeViewController().fetchOutboundFaxList()
                                    }
                                    isCheckingFaxStatus = false
                                    let replacement = "+\((outboundRecord?.country_code)!) \((outboundRecord?.fax_number!)!)"

                                    displayFaxSentSuccessAlert(TransactionID: transaction_id, primaryKey: String(format:"%d",(outboundRecord?.folder_id)!),faxnumber: replacement)
                                }
                            }
                            else
                            {
                                isCheckingFaxStatus = false
                   
                            }
                        }
                    }
                    else if String(describing: status) == "-3"
                    {
                        fax_status = FAX_STATUS.SENT.rawValue
                        isCheckingFaxStatus = false
                    }
                    else
                    {
                        fax_status = FAX_STATUS.PAID_UNSENT.rawValue
                        
                        // error_code
                        if let error_code = (dict as AnyObject).value(forKey: "error_code") as? String
                        {
                            if error_code != ""{
                                outboundRecord?.error_code = Int64(error_code)!
                            }
                        }
                        
                        
                        if let error_message = (dict as AnyObject).value(forKey: "failed_reason") as? String
                        {
                            if error_message != ""
                            {
                                outboundRecord?.message = error_message
                            }
                            else
                            {
                                outboundRecord?.message = ""
                            }
                        }
                        else
                        {
                            if let error_message = (dict as AnyObject).value(forKey: "message") as? String
                            {
                                if error_message != ""
                                {
                                    outboundRecord?.message = error_message
                                  }
                                else
                                {
                                    outboundRecord?.message = ""
                                }
                            }
                            else
                            {
                                outboundRecord?.message = ""
                            }
                        }
                        outboundRecord?.fax_status = Int64(fax_status)
                        DataModel.sharedInstance.saveContext()
                        DispatchQueue.main.async {
//                            NotificationCenter.default.post(name: Notification.Name(rawValue: FETCH_OUTBOUD_NOTIFIED), object: nil)
                            if homeVC !=  nil
                            {
                                homeVC?.fetchOutboundFaxList()
                            }
                            else    
                            {
                                HomeViewController().fetchOutboundFaxList()
                            }
                            isCheckingFaxStatus = false
                            if (fax_status == FAX_STATUS.PAID_UNSENT.rawValue)
                            {
//                                DLog("Fax Status---> " , outboundRecord?.message)
                            }
                            else if fax_status == FAX_STATUS.SENT.rawValue
                            {
                                DLog("Fax Status---> " , outboundRecord?.message)
                            }
                            if isFaxStatusCountOne == true
                            {
                                displayFaxFailedAlert(outboundRecord: outboundRecord! ,message:  dict.value(forKey: "message") as! String)
                            }
                        }
                    }
                }
                else
                {
                    isCheckingFaxStatus = false
                }
            }
            else
            {
                isCheckingFaxStatus = false
            }
        }
    }
    else
    {
        isCheckingFaxStatus = false
    }
}

func checkStatusOfSendingFax(server_ids:String)
{
    if !networkAvailability()
    {
        isCheckingFaxStatus = false
        if UIApplication.topViewController() != nil{
            DispatchQueue.main.async {
                if internetAlertCount == 1{
                    internetAlertCount = 0
                }
                else
                {
                }
            }
        }
        return
    }

    let requestData = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    requestData.setValue("\(getCurrentLanguageCode())", forKey: "country_locale")
    requestData.setValue(device_id, forKey: "device_id")
    requestData.setValue(server_ids, forKey: "server_id")
    requestData.setValue(user_id!, forKey: "user_id")
    
    let dict = NSMutableDictionary()
    dict.setValue(FAX_STATUS_OUTBOUND, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    let postStr = requestData.stringFromHttpParameters()
    DLog("FAX_STATUS_OUTBOUND  Start ")

    AppDelegate().sendAsynchronousRequestWithParameters(dict, andPostData: postStr.data(using: String.Encoding.utf8), completion: { data in
        if data != nil
        {
            do
            {
                let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
                DLog("FAX_STATUS_OUTBOUND  Stop : \(json)")
                
                if  json != nil
                {
                    handleStatusOfFaxes(dataArr: (json as NSDictionary?)!)
                }
                
                //                return json as NSDictionary?
            }
            catch
            {
                isCheckingFaxStatus = false
                return
            }
        }
        else
        {
            isCheckingFaxStatus = false
        }
        return
    })
}

func fetchRequireDataAfterLogin()
{
    // Check fax status of sending and failed faxes
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                if internetAlertCount == 0{
                    internetAlertCount += 1
                }
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    // Fax number list
    DLog(String(#line))
    getUserFaxNumbers()
    AppDelegate().fetchInboundFaxes()
    
    DispatchQueue.main.async {
        if let value = UIApplication.topViewController(){
            if value is HomeViewController
            {
                let HC = value as! HomeViewController
                HC.faxNumberBtton_Update()
            }
        }
    }
    
   // Settings from server
    DLog(String(#line))
}

func getCovertedDocument(arrayFiles:NSMutableArray, localid:NSString) -> NSArray
{
    let arrFileTemp:NSMutableArray = NSMutableArray()
    
    //     let mainPagepath = getOutgoingPath()?.appendingPathComponent(String(format:"\(localid)/sendfax_files"))
    do{
       let  coverDirectory = CreateDir(DirName: "\(localid)/sendfax_files") as NSURL
        try FileManager.default.createDirectory(at: coverDirectory as URL, withIntermediateDirectories: true, attributes: nil)
        for arrTemp in arrayFiles
        {
            let extensions = (arrTemp as! NSURL).pathExtension
            let fileName = (arrTemp as! NSURL).lastPathComponent
            let extensionArray = fileName?.components(separatedBy: ".")
            
            if supportsFile(fileName: fileName!, fromExt: SupportedImageTypeArr() as [AnyObject])
            {
                if let data = NSData(contentsOf: arrTemp as! URL)
                {
                    let image = UIImage(data: data as Data)
                    //                let filePath = ("\(arrTemp as! URL)" as NSString).deletingLastPathComponent
                    //                let fileURL = URL(string: coverDirectory)
                    let url = PDFFromImage(image!, imageName: (extensionArray?[0])!, path: coverDirectory as URL)
                    arrFileTemp .add(url)
                }
            }
            else if extensions?.lowercased() == "txt" || extensions?.lowercased() == "rtf"
            {
                if let data = NSData(contentsOf: arrTemp as! URL)
                {
                    createPDF(fileURL: coverDirectory as URL, data: data as Data, fileType: extensions!, fromAction: "common")
                }
            }
            else
            {
                arrFileTemp .add(arrTemp)
            }
        }
        

    }
    catch
    {}
    return arrFileTemp
}

func getCreditPriceChart(countryID:String,fromVC:Bool,com:((_ creditval:NSNumber)->())) {
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
                stopSpinner()
                if let value = UIApplication.topViewController()
                {
                    if value is GetCreditViewController
                    {
                        let vc = value as! GetCreditViewController
                        vc.afterResponseFromAPIPriceChart()
                    }
                }
            }
        }
        return
    }
    DispatchQueue.main.async {
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: false, color:UIColor.white)
        //         showLoadingAlert(LOADING_INDICATOR_MSG, networkIndicator: true)
    }
    let dict = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }

    let params = "country_id=\(countryID)&unique_id=\(AUTH_KEY_IFAX.md5!)&user_id=\(user_id!)&os=\(OS_NAME_AND_VERSION)&device_id=\(device_id)"
    
    // Outbound country list
    var serverDataUpdate = DataModel.sharedInstance.syncDataStatusOf(syncName: SYNC_DATA.CREDIT_PACKAGE.rawValue)
    if (UserDefaults.standard.value(forKey: DEFAULT_PRICE_CHART_ARRAY) == nil)
    {
        serverDataUpdate = true
    }
    
    //CHECK HERE CURRENT ID MATCHES WITH OLD
    let lastCountryID = getValueFromUserDefault(key: DEFAULT_LAST_COUNTRY_CODE_FOR_PRICE_CHART) as? String
    let chartArray = getValueFromUserDefault(key: DEFAULT_PRICE_CHART_ARRAY) as? NSArray 
    var symbol: NSString?
    var localDict: NSDictionary!
    if chartArray != nil {
        if chartArray!.count > 0{
            localDict = chartArray?.firstObject as! NSDictionary!
            symbol = localDict.value(forKey: "CurrencySymbol") as! NSString?
        }
    }
   
    if lastCountryID != nil && countryID == lastCountryID! && symbol != nil && serverDataUpdate != true{
        if isCreditOpenFromSettings == true
        {
            isCreditOpenFromSettings = false
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: GET_PRICE_CHART_COUNTRY_NOTIFIED_SETTING), object: nil)
        }
        else if isCreditOpenFromWizards == true
        {
            isCreditOpenFromWizards = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: GET_PRICE_CHART_COUNTRY_NOTIFIED_WIZARD), object: nil)
        }
        else
        {
            DispatchQueue.main.async {
                hideLoadingAlertWithComplition {
                    if let value = UIApplication.topViewController()
                    {
                        if value is GetCreditViewController
                        {
                            let vc = value as! GetCreditViewController
                            vc.afterResponseFromAPIPriceChart()
                        }
                    }
                }
            }
       
        }
        DispatchQueue.main.async{
        if let value = UIApplication.topViewController()
        {
            if value is GetCreditViewController
            {
                let vc = value as! GetCreditViewController
                vc.reloadCollecitonView()
            }
        }
            stopSpinner()
        }
       // return
    }
    dict.setValue(GET_CREDIT_PRICE_CHART, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: .utf8) as NSData?)
    
    if data != nil
    {
        do
        {
            let chart_dict = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            if chart_dict.value(forKey: "status") as! String == "1" {
                let data: NSArray! = chart_dict.value(forKey: "data") as! NSArray
                creditPriceChartArray = data

                
                setValueInUserDefault(key: DEFAULT_PRICE_CHART_ARRAY, value: data,isSync: false)
                setValueInUserDefault(key: DEFAULT_LAST_COUNTRY_CODE_FOR_PRICE_CHART, value: countryID, isSync: true)
                com(chart_dict["credit_per_page"] as! NSNumber)
                setValueInUserDefault(key: defalut_CREDIT_PER_PAGE, value: chart_dict["credit_per_page"],isSync: true)
               
                guard let chartArray:NSArray = getValueFromUserDefault(key: DEFAULT_PRICE_CHART_ARRAY) as? NSArray else { return }
                
                var  productListArr : [String] = []
                
                for i in 0..<chartArray.count{
                    productListArr.append((chartArray[i] as AnyObject).object(forKey: "product_name") as! String)
                }
                
                ChekcingPriceInbOrObnd = 4
                let productSet : Set = Set(productListArr)
                let pList : NSMutableArray = NSMutableArray(array: productListArr)
                setValueInUserDefault(key: "DEFAULT_CREDIT_FROMVC", value: fromVC,isSync: true)
                StoreKitHelper.sharedInstance.currentController = UIApplication.topViewController()!
//                DLog("productSet = \(productSet)")
                StoreKitHelper.sharedInstance.requestProductData(productIds: productSet, productOrderedList: pList,viewController: UIApplication.topViewController()!)
                
                // Credit Save To Server date
                var  syncObjectArr:[Last_sync_detail] = []
                syncObjectArr = DataModel.sharedInstance.fetchServerSyncData() as [Last_sync_detail]
                if syncObjectArr.count > 0
                {
                    let syncObject  = syncObjectArr[0]
                    let credit_package_server_date =  syncObject.credit_package_server_date
                    if (credit_package_server_date != nil)
                    {
                        syncObject.credit_package_local_date = credit_package_server_date
                        DataModel.sharedInstance.saveContext()
                    }
                }
            }
        }
        catch
        {
//            hideLoadingAlertWithComplition {
            DispatchQueue.main.async {
                stopSpinner()
                if let value = UIApplication.topViewController()
                {
                    if value is GetCreditViewController
                    {
                        let vc = value as! GetCreditViewController
                        vc.afterResponseFromAPIPriceChart()
                    }
                }
            }
            alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
//            }
            
//            DLog("Get Credit Pirce Chart fail")
        }
    }
    else
    {
        
        DispatchQueue.main.async {
        hideLoadingAlertWithComplition {
            if let value = UIApplication.topViewController()
            {
                if value is GetCreditViewController
                {
                    let vc = value as! GetCreditViewController
                    vc.afterResponseFromAPIPriceChart()
                }
            }
            alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
        }
        }
//        DLog("Get Credit Price chart fail")
    }
}

func getCreditCount(){
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    let dict = NSMutableDictionary()
    let unique_id = AUTH_KEY_IFAX.md5
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    var params = "device_id=\(device_id)&user_id=\(user_id!)&unique_id=%@"
    user_id = user_id!.appending(unique_id!)
    
    params =  params .replacingOccurrences(of: "%@", with:(user_id!.md5)!)
    
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    
    dict.setValue(GET_CREDIT_COUNT, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: .utf8) as NSData?)
    
    if data != nil
    {
        do
        {
            let credit_dict = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            if credit_dict.value(forKey: "status") as! String == "1" {
                let data: NSArray! = credit_dict.value(forKey: "data") as! NSArray
                setValueInUserDefault(key: DEFAULT_CREDIT_COUNT, value: ((data.object(at: 0) as! NSDictionary).value(forKey: "credit") as! Int),isSync: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: GET_CREDIT_NOTIFIED), object: nil)
            }
        } catch {}
        
    }
    else
    {
        alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
//        DLog("Get Credit Count fail")
    }
}

func generatePromoCode (){
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    
    startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.white)
    let promoDict = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    promoDict.setValue(user_id, forKey: "user_id")
    promoDict.setValue(device_id, forKey: "device_id")
    promoDict.setValue("", forKey: "store_id")
    promoDict.setValue("", forKey: "first_name")
    promoDict.setValue("", forKey: "last_name")
    let postStr = promoDict.stringFromHttpParameters()
    
    let reqDict = NSMutableDictionary()
    reqDict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    reqDict.setValue(PROMOCODE_GENERATE, forKey: "url")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(reqDict, andPostData: postStr.data(using: .utf8) as NSData?)
    if data != nil
    {
        do
        {
          let responseDictData = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            
            if responseDictData.value(forKey: "status") as! NSInteger == 1 {
                let dict: NSDictionary = responseDictData.value(forKey: "data") as! NSDictionary
//                DLog("\(dict)")
                setValueInUserDefault(key: DEFAULT_PROMO_CODE, value: dict.value(forKey: "promo_code") as! NSString,isSync: true)
//                hideLoadingAlertWithComplition {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: PROMO_CODE_NOTIFIED), object: nil)
//                }
                if isForceLoginFromSettingForShare == true{
                    NotificationCenter.default.post(name: Notification.Name(rawValue: OPEN_SHARE_SHEET_FROM_SETTINGS_FORCE_LOGIN), object: nil)
                }
            }
//             DLog("PROMO CODE : \(responseDictData)")
        }
        catch
        {
            NetworkActivityIndicatorManager.stop()
            hideLoadingAlertWithComplition {
                alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
            }
//            DLog("PROMO CODE fail")
        }
    }
    else
    {
        NetworkActivityIndicatorManager.stop()
        hideLoadingAlertWithComplition {
            alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
        }
//        DLog("PROMO CODE fail")
    }
}

func prepareOutboundFax(postStr: String) -> NSDictionary?
{
    let reqDict = NSMutableDictionary()
    reqDict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    reqDict.setValue(PREPARING_OUTBOUND_FAX, forKey: "url")
    
    //    let postStr = faxDataDict.stringFromHttpParameters()
    DLog("PREPARING_OUTBOUND_FAX Start : \(postStr)")
    
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(reqDict, andPostData: postStr.data(using: .utf8) as NSData?)
    if data != nil
    {
        do
        {
            let responseDictData = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            DLog("PREPARING_OUTBOUND_FAX Stop : \(responseDictData)")
            return responseDictData
        }
        catch
        {
//            DLog("Error with Json: \(error)")
            return nil
        }
    }
    else
    {
        
        return nil
    }
}

func verifyPromoCode(promoCode:String) {
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    DispatchQueue.main.async {
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.darkGray)
    }
    
    let promoDict = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    promoDict.setValue(user_id, forKey: "user_id")
    promoDict.setValue(device_id, forKey: "device_id")
    promoDict.setValue("", forKey: "store_id")
    promoDict.setValue(promoCode, forKey: "promo_code")
    let postStr = promoDict.stringFromHttpParameters()
    
    let reqDict = NSMutableDictionary()
    reqDict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    reqDict.setValue(PROMOCODE_VERIFY, forKey: "url")
    
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(reqDict, andPostData: postStr.data(using: .utf8) as NSData?)
    
    if data != nil
    {
        do
        {
            let responseDictData = try JSONSerialization.jsonObject(with: data as! Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            if responseDictData.value(forKey: "status") as! String == "1"{
                setValueInUserDefault(key: DEFAULT_USED_PROMO_CODE, value:promoCode, isSync: true)
                var added = MSG_2_ADDED_CREDITS
                let array:NSDictionary = responseDictData.value(forKey: "data") as! NSDictionary
                setValueInUserDefault(key: DEFAULT_CREDIT_COUNT, value: (array.value(forKey: "total_credit") as! Int),isSync: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: GET_CREDIT_NOTIFIED), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: CREDIT_SETTING_NOTIFIED), object: nil)
                let credit_added = "\(array.value(forKey: "credit_added")!)"
//                let add =  Int(credit_added)
                added = added .replacingOccurrences(of: "%@", with:credit_added)
//                DispatchQueue.main.async {
                    hideLoadingAlertWithComplition {
                        alertview(title: CREDIT_ADDED_TITLE, message: added, UIApplication.topViewController()!)
                    }
//                }
            }
            else
            {
                let failedAlert: UIAlertController = UIAlertController(title: OOPS_TITLE, message: responseDictData.value(forKey: "message") as! String?, preferredStyle: .alert)
                let okBtn = UIAlertAction(title:OK_BTN, style: .default) { action in
                    //            GetCreditViewController().redeemCodeAction(btn)
                }
                failedAlert.addAction(okBtn)
                
                DispatchQueue.main.async {
                    hideLoadingAlertWithPresentController(viewcontroller: failedAlert)
                }
            }
//            DLog("PROMO CODE VERIFY : \(responseDictData)")
        }
        catch
        {
            hideLoadingAlertWithComplition {
                alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
            }
            NetworkActivityIndicatorManager.stop()
//            DLog("PROMO CODE VERIFY fail")
        }
    }
}

func setPaymentDataToDictionaryPaymentType(type:NSInteger)-> NSMutableDictionary
{
    let dict = NSMutableDictionary()
   
    var promo_code = getValueFromUserDefault(key: DEFAULT_USED_PROMO_CODE) as? String
    
    if promo_code != "" && promo_code != nil && type != PAYMENT_TYPE.SETUP_FEE.rawValue
    {
        UserDefaults.standard.removeObject(forKey: DEFAULT_USED_PROMO_CODE)
        UserDefaults.standard.synchronize()
    }
    
    if promo_code == nil
    {
        promo_code = ""
    }

    if type == PAYMENT_TYPE.SETUP_FEE.rawValue //MARK : setup fee
    {
        dict.setValue(device_id, forKey: "UUID")
        var FaxAPIstr = ""
        if (insertPaymentInfo.value(forKey: "isd_code") as? String) == "US"
        {
            if NUMBER_PURCHASE_API == "1" || NUMBER_PURCHASE_API == FAX_API_NAME.INTERFAX.rawValue{
                FaxAPIstr = "1"
                
            }
            else if NUMBER_PURCHASE_API == "2" || NUMBER_PURCHASE_API == FAX_API_NAME.VITELITY.rawValue{
                FaxAPIstr = "2"
                dict .setValue(insertPaymentInfo.value(forKey: "fax_number"), forKey: "faxNumber")
            }
        }
        else
        {
            FaxAPIstr = "1"
        }
        if isUserLogin()
        {
            var user_id = ""
            if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
            {
                user_id = value
            }
            dict.setValue(user_id, forKey: "parentID")
        }
        dict.setValue(FaxAPIstr, forKey: "FAXAPI")
        dict.setValue(RECEIPT_DATA, forKey: "receipt-data") // Remains: receipt-data set
        dict.setValue((insertPaymentInfo.value(forKey: "monthly_amount")), forKey: "monthlyAmount")
        dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "FamilyProduct")
        dict.setValue(TRANSACTION_BY.iTUNES.rawValue, forKey: "transactionBy")
        dict.setValue(TRANSACTIONS_TYPE.INBOUNT_FIRST.rawValue, forKey: "pay_type")
        
        if insertPaymentInfo.value(forKey: "family_product") as! String == "1TIMESETUPFEE"{
            dict.setValue(Float(9.99), forKey: "amount")
        }
        else if insertPaymentInfo.value(forKey: "family_product") as! String == "1TIMESETUPFEE1"{
        dict.setValue(Float(14.99), forKey: "amount")

        }
        else if insertPaymentInfo.value(forKey: "family_product") as! String == "1TIMESETUPFEE2"{
            dict.setValue(Float(24.99), forKey: "amount")

        }
        else if insertPaymentInfo.value(forKey: "family_product") as! String == "1TIMESETUPFEE3"{
            dict.setValue(Float(34.99), forKey: "amount")

        }
        dict.setValue(device_token, forKey: "token")
        dict.setValue(insertPaymentInfo.value(forKey: "area_code"), forKey: "AreaCode")
        dict.setValue(insertPaymentInfo.value(forKey: "country"), forKey: "Country")
        dict.setValue(insertPaymentInfo.value(forKey: "pages_allowed"), forKey: "pagesAllowed")
        dict.setValue(insertPaymentInfo.value(forKey: "isd_code"), forKey: "isdCode")
        dict.setValue(IS_SANDBOX_OR_PRODUCTION_MODE ? "YES":"NO", forKey: "sandBox")
        dict.setValue(BUNDLE_VERSION, forKey: "app_version")
        dict.setValue(OS_VERSION, forKey: "iosVersion")
        dict.setValue("YES", forKey: "newReceipt")
        dict.setValue(OS_NAME_AND_VERSION, forKey: "os")
    }
    else if type == PAYMENT_TYPE.MONTHLY_FEE.rawValue //MARK : Monthly fee
    {
        var FaxAPIstr = ""
        if (insertPaymentInfo.value(forKey: "isd_code") as? String) == "US"
        {
            if NUMBER_PURCHASE_API == "1" || NUMBER_PURCHASE_API == FAX_API_NAME.INTERFAX.rawValue{
                FaxAPIstr = "1"
                dict .setValue(insertPaymentInfo.value(forKey: "zone_id"), forKey: "ZoneId")
            }
            else if NUMBER_PURCHASE_API == "2" || NUMBER_PURCHASE_API == FAX_API_NAME.VITELITY.rawValue{
                FaxAPIstr = "2"
                dict .setValue(insertPaymentInfo.value(forKey: "fax_number"), forKey: "faxNumber")
            }
        }
        else{
            FaxAPIstr = "1"
        }
        if trialMode == true && (insertPaymentInfo.value(forKey: "isd_code") as? String) == "US" && NUMBER_PURCHASE_API == "2"{
            GetIDFromSubinserAction = ""
        }
        var user_id = ""
        if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        {
            user_id = value
        }
        
        dict.setValue(device_id, forKey: "UUID")
        dict.setValue(user_id, forKey: "parentID")
        dict.setValue(RECEIPT_DATA, forKey: "receipt-data") // Remains: receipt-data set
        dict.setValue(insertPaymentInfo.value(forKey: "area_code"), forKey: "AreaCode")
        dict.setValue(insertPaymentInfo.value(forKey: "country"), forKey: "Country")
        dict.setValue(insertPaymentInfo.value(forKey: "pages_allowed"), forKey: "pagesAllowed")
        dict.setValue(insertPaymentInfo.value(forKey: "isd_code"), forKey: "isdCode")
        dict.setValue(insertPaymentInfo.value(forKey: "monthly_amount"), forKey: "monthlyAmount")
        dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "FamilyProduct")
        dict.setValue(insertPaymentInfo.value(forKey: "sub_type"), forKey: "subtype")
        dict.setValue(OS_NAME, forKey: "OS")

        dict.setValue(TRANSACTIONS_TYPE.INBOUNT_MONTHLY.rawValue, forKey: "pay_type")
        dict.setValue(insertPaymentInfo.value(forKey: "amount"), forKey: "amount")
        dict.setValue(device_token, forKey: "token")
        dict.setValue(IS_SANDBOX_OR_PRODUCTION_MODE ? "YES":"NO", forKey: "sandBox")
        dict.setValue(FaxAPIstr, forKey: "FAXAPI")
        dict.setValue(GetIDFromSubinserAction, forKey: "id")
        dict.setValue(BUNDLE_VERSION, forKey: "app_version")
        dict.setValue(OS_VERSION, forKey: "iosVersion")
        dict.setValue("YES", forKey: "newReceipt")
        dict.setValue(TRANSACTION_BY.iTUNES.rawValue, forKey: "transactionBy")
        dict.setValue(promo_code, forKey: "promo_code")
    }
    else if type == PAYMENT_TYPE.EXTEND_NUMBER.rawValue //MARK : Extend Number
    {
        var user_id = ""
        if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        {
            user_id = value
        }
        // Remains: userName set value
        dict.setValue(user_name, forKey: "userName")
        dict.setValue(device_id, forKey: "UUID")
        dict.setValue(user_id, forKey: "parentID")
        dict.setValue(RECEIPT_DATA, forKey: "receipt-data")
        dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "FamilyProduct")
        dict.setValue(insertPaymentInfo.value(forKey: "sub_type"), forKey: "subtype")
        dict.setValue(OS_NAME, forKey: "OS")
        dict.setValue(TRANSACTIONS_TYPE.INBOUNT_EXCEED.rawValue, forKey: "pay_type")
        dict.setValue(insertPaymentInfo.value(forKey: "amount"), forKey: "amount")
        dict.setValue(TRANSACTION_BY.iTUNES.rawValue, forKey: "transactionBy")
        dict.setValue(BUNDLE_VERSION, forKey: "app_version")
        dict.setValue(IS_SANDBOX_OR_PRODUCTION_MODE ? "YES":"NO", forKey: "sandBox")
        dict.setValue(OS_VERSION, forKey: "iosVersion")
        dict.setValue("YES", forKey: "newReceipt")
    }
    else if type == PAYMENT_TYPE.CREDIT.rawValue  // //MARK : BUY CREDITS
    {
        var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if user_id == nil
        {
            user_id = ""
        }
        dict.setValue(device_id, forKey: "UDID")
        dict.setValue(BUNDLE_VERSION, forKey: "app_version")
        dict.setValue(insertPaymentInfo.value(forKey: "productName"), forKey: "FamilyProduct")
        dict.setValue(OS_NAME_AND_VERSION, forKey: "os")
        dict.setValue(IS_SANDBOX_OR_PRODUCTION_MODE ? "YES":"NO", forKey: "sandBox")
        dict.setValue(user_id, forKey: "parentID")
        dict.setValue(RECEIPT_DATA, forKey: "receipt-data")
        dict.setValue(TRANSACTION_BY.CREDIT.rawValue, forKey: "pay_type")
        dict.setValue(TRANSACTION_BY.iTUNES.rawValue, forKey: "transactionBy")
        dict.setValue(OS_VERSION, forKey: "iosVersion")
        dict.setValue("YES", forKey: "newReceipt")
        dict.setValue(promo_code, forKey: "promo_code")
    }
    else if type == PAYMENT_TYPE.SEND_FAX.rawValue  //MARK : SendFax
    {
        SERVER_ID = ""
        if let id = wizardController?.outboundEntity?.server_id
        {
            if id == 0
            {
                SERVER_ID = ""
            }
            else
            {
                SERVER_ID = "\((id))"
            }
        }
        dict.setValue("", forKey: "amount")
        if let amount = (insertPaymentInfo.value(forKey: "amount"))
        {
            dict.setValue(amount, forKey: "amount")
        }
        dict.setValue(BUNDLE_VERSION, forKey: "app_version")
        dict.setValue(insertPaymentInfo.value(forKey: "productName"), forKey: "FamilyProduct")
        
        var number = ""
        if let c_Code:Int64 = wizardController?.outboundEntity?.country_code as Int64?, let f_Number = wizardController?.outboundEntity?.fax_number
        {
            number = "+\(c_Code) \(f_Number)" as String
        }
        number = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        dict.setValue(number, forKey: "faxNumber")
        if let value = wizardController?.outboundEntity?.folder_id
        {
            dict.setValue("\(value)", forKey: "LocalId")
        }
        else
        {
            dict.setValue("", forKey: "LocalId")
        }
        dict.setValue(OS_VERSION, forKey: "iosVersion")
        dict.setValue("YES", forKey: "newReceipt")
        dict.setValue(OS_NAME_AND_VERSION, forKey: "os")
        
        var user_id = ""
        if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        {
            user_id = value
        }
        dict.setValue(user_id, forKey: "parentID")
        dict.setValue(TRANSACTIONS_TYPE.SEND_FAX.rawValue, forKey: "pay_type")
        
        dict.setValue(promo_code, forKey: "promo_code")
        dict.setValue("", forKey: "receipt-data")
        if RECEIPT_DATA != nil
        {
            dict.setValue(RECEIPT_DATA!, forKey: "receipt-data")
        }
        dict.setValue(IS_SANDBOX_OR_PRODUCTION_MODE ? "YES":"NO", forKey: "sandBox")
        dict.setValue(SERVER_ID, forKey: "server_id")
        dict.setValue(TRANSACTION_BY.iTUNES.rawValue, forKey: "transactionBy")
        dict.setValue(device_id, forKey: "UDID")
        
        var required_credit:Int64 = 0
        if let value = insertPaymentInfo.value(forKey: "requiredCredit") as? String
        {
            required_credit = Int64(value)!
        }
        else if let value = insertPaymentInfo.value(forKey: "requiredCredit") as? Int64
        {
             required_credit = Int64(value)
        }
        else if  wizardController?.outboundEntity?.credits != nil
        {
            if let values = wizardController?.outboundEntity?.credits as Int64?
            {
                required_credit = values
            }
        }
        
        
        if (sendFaxWithUseCreditOption && (required_credit > 0))
        {
            if let value = insertPaymentInfo.value(forKey: "amount") as? String
            {
                var amount1 = Float("\(value)")!
                if let rCredit = insertPaymentInfo.value(forKey: "requiredCredit")
                {
                    var requiredCredit : Float = rCredit as! Float
                    let creditMultiplier = getValueFromUserDefault(key: CREDIT_MULTIPLIER) as! Float
                    
                    requiredCredit = requiredCredit/creditMultiplier
                    amount1+=0.01
                    let remainCredit = Int64((amount1*7)-requiredCredit)
                    
                    if  remainCredit > 0
                    {
                        dict.setValue("\(remainCredit)", forKey: "add_credit")
                        insertPaymentInfo.setValue(Int64(0), forKey: "requiredCredit")
                    }
                }
            }
        }
    }
    return dict
}
func sendOutboudFaxPaymentData(status:String)
{
//    DLog("Subinsert purchase(). \(Date())")
    if wizardController != nil && wizardController?.outboundEntity != nil
    {
        wizardController?.outboundEntity?.fax_status = Int64(FAX_STATUS.PAID_UNSENT.rawValue)
        DataModel.sharedInstance.saveContext()
    }

    if !networkAvailability()
    {
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
                return
                
            }
        }
        return
    }
    var dict = NSMutableDictionary()
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    dict = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.SEND_FAX.rawValue)
    dict.setValue(status, forKey: "local_receipt_status")
    user_id = user_id?.appending(AUTH_KEY_IFAX.md5!)
    do
    {
        let jsonStr = NSString.init(data: try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted), encoding: String.Encoding.utf8.rawValue)
        let params = String(format:"Data=[%@]&unique_id=%@",jsonStr!,(user_id?.md5!)!)
        let reqDict = NSMutableDictionary()
        reqDict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        reqDict.setValue(SEND_PAYMENT_DATA, forKey: "url")
        DLog("SEND_PAYMENT_DATA Start ==> \(reqDict) \(params)")
        let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(reqDict, andPostData: params.data(using: .utf8) as NSData?)
        
        if data != nil
        {
            _ = NSString.init(data: data as! Data, encoding: String.Encoding.utf8.rawValue)
//            DLog("\(res)")
            let responseDictData = try JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            DLog("SEND_PAYMENT_DATA  Stop \(responseDictData)")
            hideLoadingAlert()
            if responseDictData.value(forKey: "receipt_verify") as! String == "YES"
            {
                if wizardController != nil && wizardController?.outboundEntity != nil
                {
                    let serverID  = responseDictData.value(forKey: "ID")
                    if let value =  serverID as? NSNumber{
                        wizardController?.outboundEntity?.server_id = Int64("\(value)")!
                    }
                    wizardController?.outboundEntity?.fax_status = Int64(FAX_STATUS.PAID_UNSENT.rawValue)
                    wizardController.outboundEntity?.transaction_by = "\(TRANSACTION_BY.iTUNES.rawValue)"
                    DataModel.sharedInstance.saveContext()
                    
                    if UIApplication.topViewController() is WizardViewController
                    {
                        let values = UIApplication.topViewController() as! WizardViewController
                        values.dismiss(animated: true , completion: {
                            NotificationCenter.default.removeObserver(wizardController, name:NSNotification.Name(rawValue: COUNTRY_SELECTION_NOTIFIED_WIZARD), object: nil)
                            sendFaxWithUseCreditOption = false
                            DataModel.sharedInstance.saveContext()
                            values.removeAllExtraCoverpageDemo()
                            })
                    }
                    prepareSendFaxDataForServer(mode: SEND_FAX_MODE.NEW_FAX.rawValue,outboundEntity: (wizardController?.outboundEntity)!)
                }
                else
                {
                    if localID != ""
                    {
                        let pKey = Int(localID)
                        if pKey != nil
                        {
                            let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(pKey!)
                            if outboundMessages.count > 0{
                                let outboundEntity = outboundMessages[0]
                                prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue,outboundEntity: outboundEntity)
                            }
                            localID = ""
                        }
                    }
                }
            }
            else
            {
                alertview(title: TITLE_PURCHASE_UNSUCCESS, message: PURCHASE_UNSUCCESS1, UIApplication.topViewController()!)
            }
        }
    }
    catch
    {
//        DLog("\(String(#line))...Something wrong")
        hideLoadingAlertWithComplition {
        alertview(title: TITLE_PURCHASE_UNSUCCESS, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
        }
    }
}


func settingDataFromsServer()
{
    if networkAvailability()
    {
        let dict = NSMutableDictionary()
        dict.setValue(SETTINGS, forKey: "url")
        dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        
        var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if user_id == nil
        {
            user_id = ""
        }
        
        let params = String(format:"device_id=%@&user_id=%@&token=%@&os=%@&location=%@&app_version=%@" , arguments: [device_id, user_id!, device_token,OS_NAME_AND_VERSION,timeZoneName,Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String])
//        DLog("\(params)")
        NetworkActivityIndicatorManager.start()
        AppDelegate().sendAsynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8
            ), completion: { data in
                if data != nil
                {
                    do
                    {
                        let dataResponse = try JSONSerialization.jsonObject(with: data! as Data, options: .mutableContainers) as! NSMutableDictionary
//                        DLog("settings.php... \(dataResponse)")
                        let dataDict = (dataResponse.value(forKey: "data") as! NSArray).object(at: 0) as! NSDictionary
                        
                        if let value = dataDict.value(forKey: ZENDESK_SDK_UP) as? String
                        {
                            UserDefaults.standard.setValue(value, forKey: ZENDESK_SDK_UP)
                        }
                        if let value = dataDict.value(forKey: ZENDESK_CHAT_UP) as? String
                        {
                            UserDefaults.standard.setValue(value, forKey: ZENDESK_CHAT_UP)
                        }
                        if let value = dataDict.value(forKey: SEND_FAX_ID) as? Int
                        {
                            UserDefaults.standard.setValue(value, forKey: SEND_FAX_ID)
                        }
                        
                        if let value = dataDict.value(forKey: CREDIT_MULTIPLIER) as? Int
                        {
                            UserDefaults.standard.setValue(Float(value), forKey: CREDIT_MULTIPLIER)
                        }
                        
                        if let value = dataDict.value(forKey: "credit") as? Int
                        {
                            setValueInUserDefault(key: DEFAULT_CREDIT_COUNT, value:value,isSync:false)
                            if value < 0
                            {
                                setValueInUserDefault(key: DEFAULT_CREDIT_COUNT, value:0,isSync:false)
                            }
                            UserDefaults.standard.synchronize()
                            NotificationCenter.default.post(name: Notification.Name(rawValue: GET_CREDIT_NOTIFIED), object: nil)
                        }
                        
                        let sync_data = NSMutableDictionary()
                        if let value = dataDict.value(forKey: "credit_package") as? String
                        {
                            var date: NSDate?
                            let df =  DateFormatter()
                            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            date =  df.date(from: value) as NSDate?
                            if date != nil
                            {
                                sync_data.setObject(date!, forKey: "credit_package" as NSCopying)
                            }
                        }
                        
                        if let value = dataDict.value(forKey: "inbound_price") as? String
                        {
                            var date: NSDate?
                            let df =  DateFormatter()
                            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            date =  df.date(from: value) as NSDate?
                            if date != nil
                            {
                                sync_data.setObject(date!, forKey: "inbound_price" as NSCopying)
                            }
                        }
                        
                        if let value = dataDict.value(forKey: "outbound_price") as? String
                        {
                            var date: NSDate?
                            let df =  DateFormatter()
                            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            date =  df.date(from: value) as NSDate?
                            if date != nil
                            {
                                sync_data.setObject(date!, forKey: "outbound_price" as NSCopying)
                            }
                        }
                        if let value = dataDict.value(forKey: "force_logout") as? Int
                        {
                            if value == 1
                            {
                                forceLogout()
                            }
                        }
                        if sync_data.allKeys.count>0
                        {
                            DataModel.sharedInstance.addOrUpdateSyncData(_dates: sync_data)
                        }
                    }
                    catch
                    {
//                        DLog("\(String(#line))...Something wrong")
                    }
                }
                NetworkActivityIndicatorManager.stop()
        })
    }
}

func submitOutboundFaxDataToServer(outboundFaxData:NSMutableDictionary,mode: Int)
{
    var arrFileData:NSMutableArray = NSMutableArray()
    var dataAndFileStr:NSString = ""
    var totalFileSize:CLong = 0
    var flag:Int = 0
    if !networkAvailability(){
        isCheckingFaxStatus = false
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    let mainPagepath = getOutgoingPath()?.appendingPathComponent(String(format:"\(outboundFaxData.value(forKey: "local_id")!)/cover/MainPage_\(outboundFaxData.value(forKey: "template_no")!).pdf"))
    arrFileData = ((outboundFaxData.value(forKey: "attachment_array")!) as? NSMutableArray)!

    do {
        let fileExists = try mainPagepath?.checkResourceIsReachable()
        if fileExists == true && (outboundFaxData.value(forKey: "isCoverOn")!) as! Bool == true
        {
            arrFileData.insert((mainPagepath!), at: 0)
        }
        
    }
    catch //let error as NSError
    {
//        print(error)
    }
    
//    arrFileData = getCovertedDocument(arrayFiles: arrFileData, (outboundFaxData.value(forKey: "local_id")!) : NSString) as! NSMutableArray
    arrFileData = getCovertedDocument(arrayFiles: arrFileData, localid: "\(outboundFaxData.value(forKey: "local_id")!)" as NSString) as! NSMutableArray

    for fileurl in arrFileData
    {
        let fileName = (fileurl as! NSURL).absoluteString?.components(separatedBy: "/").last
        let extensionArray = fileName?.components(separatedBy: ".")
        let extention = extensionArray?.last
        flag = flag+1
        let data = NSMutableData.init(contentsOf:fileurl as! URL)
        
        if  extention != nil && data != nil
        {
            let currentFileStr = String(format: "file\(flag)=\("iFaxfile\(flag).\(extention!)")&data\(flag)=\(data!.base64EncodedString(options: .lineLength64Characters))&")
            if currentFileStr.length>0
            {
                dataAndFileStr = dataAndFileStr.appending(currentFileStr) as NSString
            }
            totalFileSize += currentFileStr.length
        }
    }
    
    if(totalFileSize>1024*1024*20)
    {
        alertview(title: FAX_PAGE_LIMIT_EXCEED_TITLE, message: FAX_PAGE_LIMIT_EXCEED_MSG1, UIApplication.topViewController()!)
    }
    
    var params = ""
    if let user_id = outboundFaxData.value(forKey:"user_id") as? String{
        params +=  "user_id=" + user_id + "&"
    }
    else{
        params += "user_id=&"
    }
    
    if let device_id1 = outboundFaxData.value(forKey:"device_id") as? String{
        params +=  "device_id=" + device_id1 + "&"
    }
    else{
        params +=  "device_id=&"
    }
    
    params += dataAndFileStr as String
    
    if let fax_num = outboundFaxData.value(forKey:"fax_num") as? String{
        params +=  "fax_num=" + fax_num + "&"
    }
    else{
        params +=  "fax_num=&"
    }
    
    if let recipient_name = outboundFaxData.value(forKey:RECIPIENT_NAME) as? String{
        params +=  "recipient_name=" + recipient_name + "&"
    }
    else{
        params +=  "recipient_name=&"
    }
    
    if let recipient_email = outboundFaxData.value(forKey:"recipient_email") as? String{
        params +=  "recipient_email=" + recipient_email + "&"
    }
    else{
        params +=  "recipient_email=&"
    }
    
    if let app_version = outboundFaxData.value(forKey:"app_version") as? String{
        params +=  "app_version=" + app_version + "&"
    }
    else{
        params +=  "app_version=&"
    }
    
    if let sender_email = outboundFaxData.value(forKey:"sender_email") as? String{
        params +=  "sender_email=" + sender_email + "&"
    }
    else{
        params +=  "sender_email=&"
    }
    
    if let subject = outboundFaxData.value(forKey:"subject") as? String{
        params +=  "subject=" + subject + "&"
    }
    else{
        params +=  "subject=&"
    }
    
    if let pages = outboundFaxData.value(forKey:"pages") as? String{
        params +=  "pages=" + pages + "&"
    }
    else{
        let pages = outboundFaxData.value(forKey:"pages") as! NSNumber
        params +=  "pages=" + pages.stringValue + "&"
    }
    
    if let location = outboundFaxData.value(forKey:"location") as? String{
        params +=  "location=" + location + "&"
    }
    else{
        params +=  "location=&"
    }
    
    if let local_id = outboundFaxData.value(forKey:"local_id") as? String{
        params +=  "local_id=" + local_id + "&"
    }
    else
    {
        if let local_id_numb = outboundFaxData.value(forKey:"local_id") as? NSNumber
        {
            params +=  "local_id=" + local_id_numb.stringValue + "&"
        }
        else
        {
            params +=  "local_id=&"
        }
    }
    
    if let server_id = outboundFaxData.value(forKey:"server_id") as? String
    {
        params +=  "server_id=" + server_id + "&"
    }
    else
    {
        if let server_id = outboundFaxData.value(forKey:"server_id") as? NSNumber
        {
            params +=  "server_id=" + server_id.stringValue + "&"
        }
        else
        {
            params +=  "server_id=&"
        }
    }
    
    if let country_id = outboundFaxData.value(forKey:"country_id") as? String{
        params +=  "country_id=" + country_id + "&"
    }
    else{
        params +=  "country_id=&"
    }
    
    if let page_count = outboundFaxData.value(forKey:"page_count") as? String{
        params +=  "page_count=" + page_count + "&"
    }
    else{
        let page_count = outboundFaxData.value(forKey:"page_count") as! NSNumber
        params +=  "page_count=" + page_count.stringValue + "&"
    }
    
    if let country_locale = outboundFaxData.value(forKey:"country_locale") as? String{
        params +=  "country_locale=" + country_locale + "&"
    }
    else{
        params +=  "country_locale=&"
    }
    
    if let token = outboundFaxData.value(forKey:"token") as? String{
        params +=  "token=" + device_token + "&"
    }
    else{
        params +=  "token=&"
    }
    
    if let unique_id = outboundFaxData.value(forKey:"unique_id") as? String{
        params +=  "unique_id=" + unique_id + "&"
    }
    else{
        params +=  "unique_id=&"
    }
    
    if let os = outboundFaxData.value(forKey:"os") as? String{
        params +=  "os=" + OS_NAME_AND_VERSION + "&"
    }
    else{
        params +=  "os=&"
    }
    
    if let requiredCredit = insertPaymentInfo.value(forKey: "requiredCredit")
    {
        params +=  "req_credit="+"\(requiredCredit)"+"&"
    }
    else
    {
        if let requiredCredit = outboundFaxData.value(forKey:"requiredCredit") as? NSNumber
        {
            params +=  "req_credit="+"\(requiredCredit)"+"&"
        }
    }
    if  sendFaxWithUseCreditOption
    {
        params +=  "transaction_by="+"\(TRANSACTION_BY.CREDIT.rawValue)"+"&"
        params +=  "deduct_credit="+"1"
    }
    else
    {
        
        if let transaction_by = outboundFaxData.value(forKey:"transaction_by") as? String
        {
            params +=  "transaction_by="+"\(transaction_by)"+"&"
        }
        else
        {
            params +=  "transaction_by="+"\(TRANSACTION_BY.iTUNES.rawValue)"+"&"
        }
        
        if mode == SEND_FAX_MODE.NEW_FAX.rawValue
        {
            params +=  "deduct_credit="+"0"
        }
        else
        {
            params +=  "deduct_credit="+"1"
        }
    }
    
    let dict = NSMutableDictionary()
//    var dictResponse = NSDictionary()
    
    dict.setValue(SEND_FAX_URL, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
     NetworkActivityIndicatorManager.start()
     trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SENDING_START])
    DLog("SEND_FAX_URL Request Start==> ", params)
       
    AppDelegate().sendAsynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8
    )) { (data) in
        if data != nil
        {
            do
            {
//                let response = NSString.init(data: data as! Data , encoding: String.Encoding.utf8.rawValue)
                let dictResponse = try JSONSerialization.jsonObject(with: data! as Data, options: .mutableContainers) as! NSDictionary
                DLog("SEND_FAX_URL Done.. == > \(dictResponse)")
                trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_OUTGOING_FAX,GA_ACTION:SENDING_DONE])
                if  wizardController == nil
                {
                    WizardViewController().sentSuccessfullySendFaxData(dicServerResponse: dictResponse)
                }
                else
                {
                    wizardController?.sentSuccessfullySendFaxData(dicServerResponse: dictResponse)
                }
            }catch{}
        }
   
    }

//   _ = AppDelegate().sendSynchronousRequestWithParameters11(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
}


func displayFaxFailedAlert(outboundRecord:Outbound_messages ,message:String)
{

    DispatchQueue.main.async {
        ForceSTopIndicator()
        if  alertFailedFax == nil
        {

            alertFailedFax = UIAlertController(title: OOPS_TITLE , message: message , preferredStyle: UIAlertControllerStyle.alert)
            let btnEdit = UIAlertAction(title: EDIT_NUMBER, style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                if selectedCountry.allKeys.count == 0
                {
                    if (UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) != nil)
                    {
                        let outboudArray = UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) as! NSMutableArray
                        if outboudArray.count > 0
                        {
                            let locale = NSLocale.current.regionCode
                            let filteredData2: NSArray = outboudArray.filtered(using: NSPredicate(format: "self.%@ contains[c] %@", "TerritoryCode", "\(locale!)")) as NSArray
                            if filteredData2.count > 0
                            {
                                selectedCountry = filteredData2[0] as! NSMutableDictionary
                            }
                            ForceSTopIndicator()
                        }
                        else
                        {
                            ForceSTopIndicator()
                            return
                        }
                    }
                    else
                    {
                        ForceSTopIndicator()
                        return
                    }
                }
                let ObjectsDict = NSMutableDictionary()

                ObjectsDict.setObject(outboundRecord, forKey: "outboundEntity" as NSCopying)
                ObjectsDict.setValue(OUTGOINGFAX, forKey: "action")
                
                    if UIApplication.topViewController()! is UIAlertController
                    {
                        hideLoadingAlertWithComplition {
                            if UIApplication.topViewController()! is UIAlertController
                            {
                                
                            }
                            else
                            {
                                if UIApplication.topViewController() is WizardViewController{
//                                    UIApplication.topViewController()?.dismiss(animated: true, completion: {
//                                        let vc = UIApplication.topViewController()?.storyboard?.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
//                                        vc.faxOutBoundObject =  ObjectsDict
//                                        UIApplication.topViewController()!.present(vc, animated: true, completion: nil)
//                                        
//                                    })
//                                    let value : WizardViewController = UIApplication.topViewController() as! WizardViewController
//                                    value.faxOutBoundObject =  ObjectsDict
//                                    value.viewDidLoad()
//                                    value.viewWillAppear(true)
//                                    value.viewDidAppear(true)
                                }
                                else
                                {
                                    let vc = UIApplication.topViewController()?.storyboard?.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                                    vc.faxOutBoundObject =  ObjectsDict
                                    UIApplication.topViewController()!.present(vc, animated: true, completion: nil)
                                    
                                }
                                
                            }
                        }
                    }
                    else
                    {
                        if UIApplication.topViewController() is WizardViewController{
//                            UIApplication.topViewController()?.dismiss(animated: true, completion: {
//                                let vc = UIApplication.topViewController()?.storyboard?.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
//                                vc.faxOutBoundObject =  ObjectsDict
//                                UIApplication.topViewController()!.present(vc, animated: true, completion: nil)
//                                
//                            })
                        }
                        else
                        {
                            if let value = UIApplication.topViewController()
                            {
                                if let vc:WizardViewController = value.storyboard?.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController?
                                {
                                    vc.faxOutBoundObject =  ObjectsDict
                                    UIApplication.topViewController()!.present(vc, animated: true, completion: nil)
                                }
                            }
                        }
                }
                alertFailedFax = nil
            })
            alertFailedFax.addAction(btnEdit)
            let btnResend = UIAlertAction(title: RESEND_BTN, style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                homeVC?.outgoingFaxCollectionView.reloadData()
                if networkAvailability()
                {
//                    showLoadingAlert(RESENDING_TITLE, networkIndicator: true)
                    let rCredit = outboundRecord.credits
                    let  credit = getValueFromUserDefault(key: DEFAULT_CREDIT_COUNT) as? Int64
                    
                    if credit! < rCredit
                    {
                        WizardViewController().resendFaxPayment(outboundEntity: outboundRecord)
                    }
                    else
                    {
                       prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue, outboundEntity: outboundRecord)
                    }

                    alertFailedFax = nil
                }
                else
                {
                    if let value = UIApplication.topViewController()
                    {
                        alertNetworkNotAvailableTryAgain(controller: value)

//                        alertview(title: INTERNET_CONN_TITLE, message: localisedStr, value)
                    }
                    return
                }
            })
            alertFailedFax.addAction(btnResend)
            
            let btnreportProblem = UIAlertAction(title: REPORT_PROBLEM, style: UIAlertActionStyle.destructive, handler: { (UIAlertAction) in
                
                    if UIApplication.topViewController()! is UIAlertController
                    {
                        hideLoadingAlertWithComplition {
                            if UIApplication.topViewController()! is UIAlertController
                            {
                                
                            }
                            else
                            {
                                ForceSTopIndicator()
                                homeVC?.openIfaxSupportEmail()
                            }
                        }
                    }
                    else
                    {
                        ForceSTopIndicator()
                        homeVC?.openIfaxSupportEmail()
                    }
            })
//            if #available(iOS 9.0, *)
//            {
//                btnreportProblem.setValue(UIColor.red, forKey: "titleTextColor") //CHECK IN IOS 8 ALSO
//            }

            alertFailedFax.addAction(btnreportProblem)
            
            
            let btnOK = UIAlertAction(title: CLOSE_BTN, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) in
                alertFailedFax = nil
                ForceSTopIndicator()
            })
            alertFailedFax.addAction(btnOK)
            UserDefaults.standard.setValue(DEFAULT_RESEND, forKey:"\(outboundRecord.server_id)")
            hideLoadingAlertWithPresentController(viewcontroller: alertFailedFax)
            settingDataFromsServer()
            getCreditCount()
        }
    }
}

func resendFaxWithInterFaxAPI(dicoutboudData:NSMutableDictionary,outboudEntity:Outbound_messages)
{
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }

    if !networkAvailability(){
        isCheckingFaxStatus = false
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    
    let requestData = NSMutableDictionary()
    requestData.setValue(dicoutboudData.value(forKey:"transaction_id"), forKey: "TransactionID")
//    requestData.setValue("673250684", forKey: "TransactionID")

    requestData.setValue(device_id, forKey: "device_id")
    requestData.setValue(dicoutboudData.value(forKey:"server_id"), forKey: "ID")
    requestData.setValue(user_id, forKey: "user_id")
    requestData.setValue(BUNDLE_VERSION, forKey: "app_version")
    requestData.setValue(OS_VERSION, forKey: "iosVersion")
    requestData.setValue(OS_NAME_AND_VERSION, forKey: "os")
    if let requiredCredit = insertPaymentInfo.value(forKey: "requiredCredit")
    {
        requestData.setValue("\(requiredCredit)", forKey: "req_credit")
    }
    else
    {
        if let requiredCredit = dicoutboudData.value(forKey:"requiredCredit") as? NSNumber
        {
            requestData.setValue("\(requiredCredit)", forKey: "req_credit")
        }
    }
    requestData.setValue("1", forKey: "deduct_credit")

    let dict = NSMutableDictionary()
    dict.setValue(RESEND_FAX, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    
    let postStr = requestData.stringFromHttpParameters()
    DLog(requestData)
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: postStr.data(using: String.Encoding.utf8)! as NSData?)
    if data != nil
    {
        do
        {
            DLog(String.init(data: data as! Data, encoding: String.Encoding.utf8)!)

            let reader : XMLReader = XMLReader()
            reader.rootName = "ReSendFaxResponse"
            let responseArray:[Any] = reader.parseXMLWithData(data as! Data) as [Any]
//            DLog("RESEND_FAX Response-->\(responseArray)")
            let dictResponse:NSMutableArray = NSMutableArray(array: responseArray)
            getCreditCount()
            // Save Data
            outboudEntity.fax_status = Int64(FAX_STATUS.SENT.rawValue)
            DataModel.sharedInstance.saveContext()
            DispatchQueue.main.async {
                // CALLING API FROM BACKGROUND
                DispatchQueue.global(qos: .background).async {
                    isCheckingFaxStatus = false
                    checkStatusOfFaxes(faxStatus: [FAX_STATUS.SENT.rawValue , FAX_STATUS.SENDING.rawValue])
                }
            }
            hideLoadingAlertWithComplition {
                WizardViewController().faxBeingSendingMoreAlert()
           }
            
        }
        catch
        {
           isCheckingFaxStatus = false
        }
    }
    else
    {
        hideLoadingAlertWithComplition {
            isCheckingFaxStatus = false
        }
    }
}

func displayFaxSentSuccessAlert(TransactionID:String,primaryKey:String,faxnumber:String)
{
    DispatchQueue.main.async {
        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:FAX_SEND])
        trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_OUTGOING_FAX,GA_ACTION:FAX_SEND])
        if  alertSuccessFax == nil
        {
            alertSuccessFax = nil
            var strFaxnumber = SUCCESS_MSG
            strFaxnumber =  strFaxnumber.replacingOccurrences(of: "%@", with: faxnumber)
            
            alertSuccessFax = UIAlertController(title: SUCCESS_TITLE , message: strFaxnumber , preferredStyle: UIAlertControllerStyle.alert)
            let btnView = UIAlertAction(title: VIEW_REPORT_BTN, style: UIAlertActionStyle.default, handler: {
                (UIAlertAction) in
                
                if UIApplication.topViewController()! is UIAlertController
                {
                    hideLoadingAlertWithComplition {
                        if UIApplication.topViewController()! is UIAlertController
                        {
                            
                        }
                        else
                        {
                            alertSuccessFax = nil
                            
                            //show rate alert
                            isDisplayRateAlert = showRateAlertOrNot()
                            let string = "\(primaryKey)"
                            
                            let outboundObject = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(string)!)
                            transmissionReportPath = CoverTamplate_PDFCreator().getRecieptForSent(outBound:outboundObject[0])
                            if  UIApplication.topViewController()! is PreviewTransmissionReportController
                            {
                                UIApplication.topViewController()!.dismiss(animated: true, completion: {
                                    let preview = UIApplication.topViewController()!.storyboard?.instantiateViewController(withIdentifier: "PreviewTransmissionReportController") as! PreviewTransmissionReportController
                                    preview.transitioningDelegate = overlayTransitioningDelegate
                                    preview.modalPresentationStyle = .custom
                                    UIApplication.topViewController()!.present(preview, animated:true, completion: nil)
                                })
                            }
                            else
                            {
                                if let preview : PreviewTransmissionReportController = UIApplication.topViewController()!.storyboard?.instantiateViewController(withIdentifier: "PreviewTransmissionReportController") as? PreviewTransmissionReportController
                               {
                                    preview.transitioningDelegate = overlayTransitioningDelegate
                                    preview.modalPresentationStyle = .custom
                                    UIApplication.topViewController()!.present(preview, animated:true, completion: nil)
                              }
                            }
                        }
                    }
                }
                else
                {
                    alertSuccessFax = nil
                    
                    //show rate alert
                    isDisplayRateAlert = showRateAlertOrNot()
                    let string = "\(primaryKey)"
                    
                    let outboundObject = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(string)!)
                    transmissionReportPath = CoverTamplate_PDFCreator().getRecieptForSent(outBound:outboundObject[0])
                    if transmissionReportPath.path != ""
                    {
                    
                    }
                    if  UIApplication.topViewController()! is PreviewTransmissionReportController
                    {
                        UIApplication.topViewController()!.dismiss(animated: true, completion: { 
                            let preview = UIApplication.topViewController()!.storyboard?.instantiateViewController(withIdentifier: "PreviewTransmissionReportController") as! PreviewTransmissionReportController
                            preview.transitioningDelegate = overlayTransitioningDelegate
                            preview.modalPresentationStyle = .custom
                            UIApplication.topViewController()!.present(preview, animated:true, completion: nil)
                        })
                    }
                    else
                    {
                        if let preview : PreviewTransmissionReportController = UIApplication.topViewController()!.storyboard?.instantiateViewController(withIdentifier: "PreviewTransmissionReportController") as? PreviewTransmissionReportController
                        {
                            preview.transitioningDelegate = overlayTransitioningDelegate
                            preview.modalPresentationStyle = .custom
                            UIApplication.topViewController()!.present(preview, animated:true, completion: nil)
                        }
                    }
                    
                }
            })
            alertSuccessFax.addAction(btnView)
            
            let btnClose = UIAlertAction(title: CLOSE_BTN, style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) in
                alertSuccessFax = nil
                                //show rate alert
                if showRateAlertOrNot(){
                    goToRateScreen()
                }
                
            })
            alertSuccessFax.addAction(btnClose)
            UIApplication.topViewController()!.present(alertSuccessFax, animated: true, completion: nil)
        }
    }
 }

func payAndSubscribeSubscptnPaymentType(paymentType:Int )
{
    let productName = insertPaymentInfo.value(forKey: "family_product") as! String
    insertPaymentInfo.setValue("\(paymentType)", forKey: "payment_type")
    SetupFee_PaymentDone = false

    if paymentType == PAYMENT_TYPE.MONTHLY_FEE.rawValue && ((trialMode == false && ((insertPaymentInfo.value(forKey: "isd_code") as? String) == "US")) || ((insertPaymentInfo.value(forKey: "isd_code") as? String) != "US"))
    {
        SetupFee_PaymentDone = true
    }
  
    continue_Buy = 0
    StoreKitHelper.sharedInstance.purchaseProduct(productName: productName, productQty: 1, paymentType: paymentType, viewController: nil)
}

func monthlySubscriptionAmountwithSetup(_ amount: String) -> NSMutableDictionary{
    let tempDict = NSMutableDictionary()
    let string = NSString(string: amount)
    let myAmount = string.doubleValue
    
    if myAmount >= 0.0 && myAmount < 12.5{
        tempDict.setValue("17.99", forKey: "1month")
        tempDict.setValue("16.66", forKey: "3month")
        tempDict.setValue("15.83", forKey: "6month")
        tempDict.setValue("14.17", forKey: "12month")
        
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP1201_1" : "SINSP1201", forKey: "P1month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP1203_1" : "SINSP1203", forKey: "P3month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP1206_1" : "SINSP1206", forKey: "P6month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP1212_1" : "SINSP1212", forKey: "P12month")
        
        tempDict.setValue("17.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("49.99", forKey: "AL3month")
        tempDict.setValue("94.99", forKey: "AL6month")
        tempDict.setValue("169.99", forKey: "AL12month")
        
    }
    else if myAmount >= 12.5 && myAmount < 22.5
    {
        tempDict.setValue("21.99", forKey: "1month")
        tempDict.setValue("21.66", forKey: "3month")
        tempDict.setValue("20.00", forKey: "6month")
        tempDict.setValue("19.17", forKey: "12month")
        
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP2201_1" : "SINSP2201", forKey: "P1month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP2203_1" : "SINSP2203", forKey: "P3month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP2206_1" : "SINSP2206", forKey: "P6month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP2212_1" : "SINSP2212", forKey: "P12month")
        
        tempDict.setValue("21.99", forKey: "ALmonth")
        tempDict.setValue("64.99", forKey: "AL3month")
        tempDict.setValue("119.99", forKey: "AL6month")
        tempDict.setValue("229.99", forKey: "AL12month")
        
    }
    else if myAmount >= 22.5 && myAmount < 32.5
    {
        tempDict.setValue("34.99", forKey: "1month")
        tempDict.setValue("33.33", forKey: "3month")
        tempDict.setValue("31.67", forKey: "6month")
        tempDict.setValue("30.83", forKey: "12month")
        
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3201_1" : "SINSP3201", forKey: "P1month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3203_1" : "SINSP3203", forKey: "P3month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3206_1" : "SINSP3206", forKey: "P6month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3212_1" : "SINSP3212", forKey: "P12month")
        
        tempDict.setValue("34.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("99.99", forKey: "AL3month")
        tempDict.setValue("189.99", forKey: "AL6month")
        tempDict.setValue("399.99", forKey: "AL12month")
        
    }
    else
    {
        tempDict.setValue("34.99", forKey: "1month")
        tempDict.setValue("33.33", forKey: "3month")
        tempDict.setValue("31.67", forKey: "6month")
        tempDict.setValue("30.83", forKey: "12month")
        
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3201_1" : "SINSP3201", forKey: "P1month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3201_1" : "SINSP3203", forKey: "P3month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3201_1" : "SINSP3206", forKey: "P6month")
        tempDict.setValue(isAutoRenewProduct ? "AUTO_SINP3201_1" : "SINSP3212", forKey: "P12month")
        
        tempDict.setValue("34.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("99.99", forKey: "AL3month")
        tempDict.setValue("189.99", forKey: "AL6month")
        tempDict.setValue("399.99", forKey: "AL12month")
        
    }
    return tempDict
    
}

func monthlySubscriptionAmount(_ amount: String) -> NSMutableDictionary{
    let tempDict = NSMutableDictionary()
    let string = NSString(string: amount)
    let myAmount = string.doubleValue
    var prefixforAutorenew = ""
    if isAutoRenewProduct
    {
        prefixforAutorenew  = "AUTO_"
    }
    
    if myAmount >= 0.0 && myAmount < 12.5{
        tempDict.setValue("17.99", forKey: "1month")
        tempDict.setValue("16.66", forKey: "3month")
        tempDict.setValue("15.83", forKey: "6month")
        tempDict.setValue("14.17", forKey: "12month")
        
        tempDict.setValue(String(format:"%@SINP1201" , prefixforAutorenew), forKey: "P1month")
        tempDict.setValue(String(format:"%@SINP1203" , prefixforAutorenew), forKey: "P3month")
        tempDict.setValue(String(format:"%@SINP1206" , prefixforAutorenew), forKey: "P6month")
        tempDict.setValue(String(format:"%@SINP12012" , prefixforAutorenew), forKey: "P12month")
        
        tempDict.setValue("17.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("49.99", forKey: "AL3month")
        tempDict.setValue("94.99", forKey: "AL6month")
        tempDict.setValue("169.99", forKey: "AL12month")
        
    }
    else if myAmount >= 12.5 && myAmount < 22.5
    {
        tempDict.setValue("21.99", forKey: "1month")
        tempDict.setValue("21.66", forKey: "3month")
        tempDict.setValue("20.00", forKey: "6month")
        tempDict.setValue("19.17", forKey: "12month")
        
        tempDict.setValue(String(format:"%@SINP2201" , prefixforAutorenew), forKey: "P1month")
        tempDict.setValue(String(format:"%@SINP2203" , prefixforAutorenew), forKey: "P3month")
        tempDict.setValue(String(format:"%@SINP2206" , prefixforAutorenew), forKey: "P6month")
        tempDict.setValue(String(format:"%@SINP22012" , prefixforAutorenew), forKey: "P12month")
        
        tempDict.setValue("21.99", forKey: "ALmonth")
        tempDict.setValue("64.99", forKey: "AL3month")
        tempDict.setValue("119.99", forKey: "AL6month")
        tempDict.setValue("229.99", forKey: "AL12month")
        
    }
    else if myAmount >= 22.5 && myAmount < 32.5
    {
        tempDict.setValue("34.99", forKey: "1month")
        tempDict.setValue("33.33", forKey: "3month")
        tempDict.setValue("31.67", forKey: "6month")
        tempDict.setValue("30.83", forKey: "12month")
        
        tempDict.setValue(String(format:"%@SINP3201" , prefixforAutorenew), forKey: "P1month")
        tempDict.setValue(String(format:"%@SINP3203" , prefixforAutorenew), forKey: "P3month")
        tempDict.setValue(String(format:"%@SINP3206" , prefixforAutorenew), forKey: "P6month")
        tempDict.setValue(String(format:"%@SINP32012" , prefixforAutorenew), forKey: "P12month")
        
        tempDict.setValue("34.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("99.99", forKey: "AL3month")
        tempDict.setValue("189.99", forKey: "AL6month")
        tempDict.setValue("399.99", forKey: "AL12month")
        
    }
    else
    {
        tempDict.setValue("34.99", forKey: "1month")
        tempDict.setValue("33.33", forKey: "3month")
        tempDict.setValue("31.67", forKey: "6month")
        tempDict.setValue("30.83", forKey: "12month")
        
        tempDict.setValue(String(format:"%@SINP3201" , prefixforAutorenew), forKey: "P1month")
        tempDict.setValue(String(format:"%@SINP3203" , prefixforAutorenew), forKey: "P3month")
        tempDict.setValue(String(format:"%@SINP3206" , prefixforAutorenew), forKey: "P6month")
        tempDict.setValue(String(format:"%@SINP32012" , prefixforAutorenew), forKey: "P12month")
        
        tempDict.setValue("34.99", forKey: "ALmonth") //Add +9.99$ in product price
        tempDict.setValue("99.99", forKey: "AL3month")
        tempDict.setValue("189.99", forKey: "AL6month")
        tempDict.setValue("399.99", forKey: "AL12month")
    }
    return tempDict
}


func selectGroupWithSetupFee() ->NSMutableDictionary{
    // Decide group and duration
    let myAmountString = NSString(string: insertPaymentInfo.value(forKey: "monthly_amount") as! String)
    let myAmount = myAmountString.doubleValue
    if myAmount >= 0 && myAmount < 12.5
    {
        insertPaymentInfo.setValue("A", forKey: "product_group")
    }
    else if myAmount >= 12.5 && myAmount < 22.5
    {
        insertPaymentInfo.setValue("B", forKey: "product_group")
    }
    else if myAmount >= 22.5 && myAmount < 32.5
    {
        insertPaymentInfo.setValue("C", forKey: "product_group")
    }
    else{
        insertPaymentInfo.setValue("C", forKey: "product_group")
    }
    
    // Decide setup fee product
    let setupFeeString = NSString(string: insertPaymentInfo.value(forKey: "setup_fee") as! String)
    let setupFee = setupFeeString.doubleValue
    if setupFee > 0 && setupFee <= 9.5
    {
//        DLog("SetupFee is $9.99")
        insertPaymentInfo.setValue("1TIMESETUPFEE", forKey: "family_product")
    }
    else if setupFee > 9.5 && setupFee <= 14.0
    {
//        DLog("SetupFee is $14.99")
        insertPaymentInfo.setValue("1TIMESETUPFEE1", forKey: "family_product")
    }
    else if setupFee > 14.0 && setupFee <= 22.95
    {
//        DLog("SetupFee is $24.99")
        insertPaymentInfo.setValue("1TIMESETUPFEE2", forKey: "family_product")
    }
    else if setupFee > 22.95 && setupFee <= 30.00
    {
//        DLog("SetupFee is $34.99")
        insertPaymentInfo.setValue("1TIMESETUPFEE3", forKey: "family_product")
    }
    else{
//        DLog("SetupFee is $34.99")
        insertPaymentInfo.setValue("1TIMESETUPFEE3", forKey: "family_product")
    }
    let string = insertPaymentInfo.value(forKey: "monthly_amount") as! String
    return  monthlySubscriptionAmountwithSetup(string)
    
}

func getAutoRenewProduct_group(group:String?, duration:String?){
    
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    
    var user_id = ""
    if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    {
        user_id = value
    }
    var trial_mode = ""
    var group_value = ""
    if group != nil
    {
            group_value = group!
    }
    var duration_value = ""
    if duration != nil
    {
        duration_value = duration!
    }
    if prepareInbFaxDict.count > 0{
        let dict = prepareInbFaxDict[0] as! Dictionary<String,Any>
        if let value = dict["first_time_setup"] as? String
        {
            if (insertPaymentInfo.value(forKey: "isd_code") as? String) == "US" && value == "FALSE" && trialMode == true {
                trial_mode = "1"
                group_value = "A"
                duration_value = "1"
            }
        }
    }
    let paramDict = NSMutableDictionary()
    paramDict.setValue(user_id, forKey: "parentId")
    paramDict.setValue(group_value, forKey: "group")
    paramDict.setValue(duration_value, forKey: "duration")
    paramDict.setValue(device_id, forKey: "device_id")
    paramDict.setValue(OS_NAME_AND_VERSION, forKey: "os")
    paramDict.setValue(trial_mode, forKey: "trial_mode")
    
    if group_value == nil
    {
        group_value = ""
    }
    //let params = paramDict.stringFromHttpParameters()
   let params = String(format:"parentId=%@&group=%@&duration=%@&device_id=%@&os=%@&trial_mode=%@",user_id,group_value,duration_value,device_id,OS_NAME_AND_VERSION,trial_mode)
    
    let dict = NSMutableDictionary()
    dict.setValue(GET_AUTO_RENEW_PRODUCT, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")

//    DLog("Request : Get autorenew product URl ->\(dict) \(params)")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    if data != nil
    {
        do
        {
            let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//            DLog("getAutoRenewProduct_group Response : \(json)" )
            if let value = json["message"] as? String{
                autorenewProduct = value
            }
            else{
                if let name = json["product_name"] as? String{
                    autorenewProduct = name
                }
            }
        }catch {
//            DLog("Error with Json: \(error)")
            let ErrorDesc = error.localizedDescription
            alertview(title: ERROR_TITLE, message: ErrorDesc, UIApplication.topViewController()!)
        }
    }
    else{
        autorenewProduct = "limit_exceed"
        alertview(title: TITLE_CONNECTION_LOST, message: PLEASE_TRY_AGAIN_MSG, UIApplication.topViewController()!)
    }
}

func sendInboundFaxPaymentToServer_SubscptnPlan(_ dataDict : NSMutableDictionary){

    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            alertNetworkNotAvailableTryAgain(controller: value)
        }
        return
    }
    var jsonDictionary = NSMutableDictionary()
    var subscriptionPlan = ""
    if let value = dataDict.value(forKey:"sub_type"){
        subscriptionPlan = value as! String
    }
    if subscriptionPlan == K_PAYSUBSCRIPTION_ID_1 || subscriptionPlan == K_PAYSUBSCRIPTION_ID_3 || subscriptionPlan == K_PAYSUBSCRIPTION_ID_6 || subscriptionPlan == K_PAYSUBSCRIPTION_ID_12{
        
        let myString = insertPaymentInfo.value(forKey:"family_product") as! String
        let subString = myString.substring(to: myString.index(myString.startIndex, offsetBy: 5))
        if (myString as NSString).range(of: TRANSACTIONS_TYPE.INBOUNT_FIRST.rawValue).location != NSNotFound{
            GetIDFromSubinserAction = ""
            //Remians: store in database
            
            let transctionRecords : [Inbound_transactions] = DataModel.sharedInstance.fetchAllInboundTransctions()
            if transctionRecords.count > 0{
                jsonDictionary  = getInboundTransctionDictionary(transctionRecords[0])
            }
            else
            {
                let data = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.SETUP_FEE.rawValue)
                jsonDictionary = NSMutableDictionary(dictionary: data)
                insertInboundTransction(data)
            }
            let data = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.SETUP_FEE.rawValue)
            jsonDictionary = NSMutableDictionary(dictionary: data)
            sendSetupFeeDataToServer(jsonDictionary)
        }
        else if subString == "AUTO_"{
           
            if let value = UserDefaults.standard.value(forKey: PAYMENT_INFO_FIRSTTIME_SETUP_TRANSACTION) as? NSDictionary{
                GetIDFromSubinserAction = value.value(forKey: "id") as! String
            }
            let dict = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.MONTHLY_FEE.rawValue) 
            GetFaxNumber_jsonData(dict)
        }
        else {
            hideLoadingAlert()
        }
    }
    else if subscriptionPlan == K_SUBSCRIPTION_ID_1 || subscriptionPlan == K_SUBSCRIPTION_ID_3 || subscriptionPlan == K_SUBSCRIPTION_ID_6 || subscriptionPlan == K_SUBSCRIPTION_ID_12{
        let transctionRecords : [Inbound_transactions] = DataModel.sharedInstance.fetchAllInboundTransctions()
        if transctionRecords.count > 0{
            jsonDictionary = getInboundTransctionDictionary(transctionRecords[0])
        }
        else{
            if isAutoRenewProduct
            {
                let data = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.EXTEND_NUMBER.rawValue)
                jsonDictionary = NSMutableDictionary(dictionary: data)
                insertInboundTransction(data)
            }
        }
        let data1 = setPaymentDataToDictionaryPaymentType(type: PAYMENT_TYPE.EXTEND_NUMBER.rawValue)
        jsonDictionary = NSMutableDictionary(dictionary: data1)
        var strPromocode = ""
        if let value = getValueFromUserDefault(key: DEFAULT_USED_PROMO_CODE) as? String {
            strPromocode = value
            removeValueFromUserDefault(key: DEFAULT_USED_PROMO_CODE,isSync:true)
        }
        jsonDictionary.setValue(strPromocode, forKey: "promo_code")
        jsonDictionary.setValue(user_name, forKey: "userName")
        
        let jsonData =  try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as NSString
        let params = String(format:"Data=[%@]",jsonString)
        let dict = NSMutableDictionary()
        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SEND_PAYMENT_DATA_TO_SERVER])
        trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_FAXNUMBER,GA_ACTION:SEND_PAYMENT_DATA_TO_SERVER])
        dict.setValue(EXTEND_FAX_NUMBER, forKey: "url")
        dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
//        DLog("Request : extend fax number -> \(dict)  \(params)")

        let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
//        DLog("Request : extend fax number -> \(data) ")

        if data != nil
        {
            do
            {

                let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//                DLog("sendInboundFaxPaymentToServer_SubscptnPlan  Response : \(json)" )
                let reciept_response = json["receipt_response"] as? String
                let status = json["response"] as? String
//                if let value = json["receipt_response"] as? String{
                    if reciept_response == "YES" && status! == "SUCCESS"
                    {
                        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:FAX_NUMBER_EXTEND])
//                        print(jsonDictionary)
                        if jsonDictionary.value(forKey: "FamilyProduct") != nil && jsonDictionary.value(forKey: "amount") != nil && jsonDictionary.value(forKey: "pay_type") != nil
                        {
                            let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", jsonDictionary.value(forKey: "FamilyProduct") as! CVarArg, jsonDictionary.value(forKey: "amount") as! CVarArg, jsonDictionary.value(forKey: "pay_type") as! CVarArg)
                            DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                        }
                        removeValueFromUserDefault(key: REMAIN_DAY_FOR_EXTEND_SUB,isSync:true)
                        
                        //This is for subscription
                        let strAlertMsg = "Your subscription period has been extended for "+strSubPeriod
                        isPassPaymentInfo = true                       
                        
                        let alertController = UIAlertController(title: PURCHASE_SUCCESS_TITLE, message: strAlertMsg, preferredStyle: .alert)
                        let ok = UIAlertAction(title: OK_BTN, style: .default, handler: { (action) -> Void in
                            if UIApplication.topViewController()! is FaxNumberManageController
                            {
                                UIApplication.topViewController()!.dismiss(animated: true, completion: {
                                    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
                                    getUserFaxNumbers()
                                })
                            }
                        })
                        alertController.addAction(ok)
                        if UIApplication.topViewController() != nil{
                            hideLoadingAlertWithPresentController(viewcontroller : alertController)
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                        hideLoadingAlertWithComplition {
                            let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", jsonDictionary.value(forKey: "FamilyProduct") as! CVarArg, jsonDictionary.value(forKey: "amount") as! CVarArg, jsonDictionary.value(forKey: "pay_type") as! CVarArg)
                            DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                            return
                            }
                        }
                    }
//                }
            }
            catch
            {
//                DLog("json error: \(error)")
                alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                
            }
        }
    }
}

func insertInboundTransction(_ value:NSDictionary){
//    DLog(" Insert inbound transction record: \(value)")
    let array:[NSDictionary] = [value]
    MigrateDataBase.sharedInstance.paymentInfoDataMigratingOnCoreDatabase(records: array)
}

func getInboundTransctionDictionary(_ object: Inbound_transactions) -> NSMutableDictionary{
    let dataDict = NSMutableDictionary()
    var product_name =  ""
    if let transctionObj = object.transaction{
        
        //String properties
        if let value = transctionObj.app_version
        {
            dataDict.setValue(value, forKey: "app_version")
        }
        else
        {
            dataDict.setValue("", forKey: "app_version")
        }
        
        if let value = transctionObj.device_id
        {
            dataDict.setValue(value, forKey: "UUID")
        }
        else
        {
            dataDict.setValue("", forKey: "UUID")
        }
        
        if let value = transctionObj.product_name
        {
            dataDict.setValue(value, forKey: "FamilyProduct")
            product_name = value
        }
        else
        {
            dataDict.setValue("", forKey: "FamilyProduct")
        }
        
        if let value = transctionObj.receipt_data
        {
            dataDict.setValue(value, forKey: "receipt-data")
        }
        else
        {
            dataDict.setValue("", forKey: "receipt-data")
        }
        
        if let value = transctionObj.transaction_by
        {
            dataDict.setValue(value, forKey: "transactionBy")
        }
        else
        {
            dataDict.setValue("", forKey: "transactionBy")
        }
        
        if let value = transctionObj.user_id
        {
            dataDict.setValue(value, forKey: "parentID")
        }
        else{
            dataDict.setValue("", forKey: "parentID")
        }
        
        dataDict.setValue(transctionObj.amount, forKey: "amount")
        
        
        if let value = transctionObj.transaction_type
        {
            dataDict.setValue(value, forKey: "pay_type")
        }
        else
        {
            dataDict.setValue("", forKey: "pay_type")
        }
        

        
        if (product_name as NSString).range(of: TRANSACTIONS_TYPE.INBOUNT_FIRST.rawValue).location != NSNotFound
        {
            if let value = transctionObj.os
            {
                dataDict.setValue(value, forKey: "os")
            }
        }
        else
        {
            if let value = transctionObj.os
            {
                dataDict.setValue(value, forKey: "OS")
            }
            //Int64 properties
            if transctionObj.server_id != 0
            {
                dataDict.setValue("\(transctionObj.server_id)", forKey: "id")
            }
            else
            {
                dataDict.setValue("", forKey: "id")
            }
        }
    }
    
    
    if let value = object.area_code{
        dataDict.setValue(value, forKey: "AreaCode")
    }
    else{
        dataDict.setValue("", forKey: "AreaCode")
    }
    if let value = object.country{
        dataDict.setValue(value, forKey: "Country")
    }
    else{
        dataDict.setValue("", forKey: "Country")
    }
    if let value = object.fax_api{
        dataDict.setValue(value, forKey: "FAXAPI")
    }
    else{
        dataDict.setValue("", forKey: "FAXAPI")
    }
    if let value = object.fax_number{
        dataDict.setValue(value, forKey: "faxNumber")
    }
    else{
        dataDict.setValue("", forKey: "faxNumber")
    }
    if let value = object.isd_code{
        dataDict.setValue(value, forKey: "isdCode")
    }
    else{
        dataDict.setValue("", forKey: "isdCode")
    }
    if let value = object.pages_allowed{
        dataDict.setValue(value, forKey: "pagesAllowed")
    }
    else{
        dataDict.setValue("", forKey: "pagesAllowed")
    }
       if let value = object.token{
        dataDict.setValue(value, forKey: "token")
    }
    else{
        dataDict.setValue("", forKey: "token")
    }
    
    
    dataDict.setValue(object.monthly_amount, forKey: "monthlyAmount")

//    if let value = object.monthly_amount as? NSNumber
//    {
//    }
//    else
//    {
//        dataDict.setValue("", forKey: "monthly_amount")
//    }
    
    if let value = object.sand_box
    {
        dataDict.setValue(value, forKey: "sandBox")
    }
    else
    {
        dataDict.setValue("", forKey: "sandBox")
    }
     if (product_name as NSString).range(of: TRANSACTIONS_TYPE.INBOUNT_FIRST.rawValue).location == NSNotFound
    {
        if let value = object.promo_code
        {
            dataDict.setValue(value, forKey: "promo_code")
        }
        else
        {
            dataDict.setValue("", forKey: "promo_code")
        }
        
        if let value = object.zone_id
        {
            dataDict.setValue(value, forKey: "ZoneId")
        }
        else
        {
            dataDict.setValue("", forKey: "ZoneId")
        }
        
        if let value = object.user_name{
            
            dataDict.setValue(value, forKey: "userName")
        }
        else
        {
            dataDict.setValue(user_name, forKey: "userName")
        }
        
        if let value = object.sub_type
        {
            dataDict.setValue(value, forKey: "subtype")
        }
        else
        {
            dataDict.setValue("", forKey: "subtype")
        }
    }
    dataDict.setValue(OS_VERSION, forKey: "iosVersion")
    dataDict.setValue("YES", forKey: "newReceipt")

    return dataDict
}

func GetFaxNumber_jsonData(_ dataDict:NSMutableDictionary){

    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SEND_MONTHLY_FEE_DATA_TO_SERVER])
    trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_FAXNUMBER,GA_ACTION:SEND_MONTHLY_FEE_DATA_TO_SERVER])
    var jsonDictionary = NSMutableDictionary()
    jsonDictionary = dataDict
    if jsonDictionary.value(forKey: "AutoRenew") == nil
    {
         let transctionRecords : [Inbound_transactions] = DataModel.sharedInstance.fetchAllInboundTransctions()
        if transctionRecords.count > 0
        {
            jsonDictionary = getInboundTransctionDictionary(transctionRecords[0])
        }
        else
        {
            insertInboundTransction(jsonDictionary)
        }
    }
    var strPromocode = ""
    if let value = getValueFromUserDefault(key: DEFAULT_USED_PROMO_CODE) as? String {
        strPromocode = value
        removeValueFromUserDefault(key: DEFAULT_USED_PROMO_CODE,isSync:true)
    }
    jsonDictionary.setValue(strPromocode, forKey: "promo_code")
    
// Static number purchase from interfax
//    jsonDictionary.setValue("United States of America", forKey: "Country")
//    jsonDictionary.setValue("917", forKey: "AreaCode")
//    jsonDictionary.setValue("US", forKey: "isdCode")
//     jsonDictionary.setValue("1513", forKey: "ZoneId")
//     jsonDictionary.setValue("CR.00000000000037406", forKey: "userName")
    
//    DLog(" : jsonDictionary -> \(jsonDictionary) ")

    let jsonData =  try! JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as NSString
    let params = String(format:"Data=[%@]",jsonString)
    let dict = NSMutableDictionary()
    dict.setValue(BUY_FAX_NUMBER, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    
//    DLog("BUY_FAX_NUMBER Request : Buy fax number -> \(dict)  \(params)")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    if data != nil
    {
        do
        {
            let res = NSString.init(data: data as! Data, encoding: String.Encoding.utf8.rawValue)

            let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//            DLog("BUY_FAX_NUMBER Response : \(json)" )
            if let value = json["receipt_response"] as? String
            {
                if value == "YES"
                {
                    if jsonDictionary.value(forKey: "AutoRenew") == nil
                    {
                        if jsonDictionary.value(forKey: "FamilyProduct") != nil && jsonDictionary.value(forKey: "amount") != nil && jsonDictionary.value(forKey: "pay_type") != nil
                        {
                            let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", jsonDictionary.value(forKey: "FamilyProduct") as! CVarArg, jsonDictionary.value(forKey: "amount") as! CVarArg, jsonDictionary.value(forKey: "pay_type") as! CVarArg)
                            
                            DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                        }
                    }
                    removeValueFromUserDefault(key: PAYMENT_INFO_FIRSTTIME_SETUP_TRANSACTION,isSync:true)

                    if let value = json["status"] as? String
                    {
                        if value == "ok"
                        { // Fax Number Purchased
                           DLog("--------- Fax number purchase success ---------")
                            
                            // Start Glowing Animation On Fax Number Button In Home Screen
                            UserDefaults.standard.set(true, forKey: START_GLOWING_ANIMATION)
                            UserDefaults.standard.synchronize()
                            
                            var faxnumber = ""
                            if let value = json["FaxNumber"] as? String{
                                faxnumber = value
                            }
                            if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
                            {
                                
                            }
                            getUserFaxNumbers()
                            let formattedFaxNumber = faxnumber.formatFaxNumber!
                            let message = NUMBER_MANAGE_SUBSCRIPTION.replacingOccurrences(of: "%@", with: formattedFaxNumber)
                            trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:FAX_NUMBER_PURCHASED])
                            trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_FAXNUMBER,GA_ACTION:FAX_NUMBER_PURCHASED])
                            hideLoadingAlertWithComplition {
                                
                                if let  value = UIApplication.topViewController()
                                {
                                    value.dismiss(animated: true, completion: {
                                       
                                        let alert = UIAlertController(title:FAX_NUMBER_ACTIVATED_TITLE , message:message , preferredStyle: UIAlertControllerStyle.alert)
                                        let close = UIAlertAction(
                                            title: CLOSE_BTN,
                                            style: UIAlertActionStyle.default,
                                            handler: { (action) -> Void in
                                                
                                        })
                                       
                                        let share = UIAlertAction(
                                            title: SHARE,
                                            style: UIAlertActionStyle.default,
                                            handler: { (action) -> Void in
                                                homeVC?.sharFaxNumber(FaxNumeber: "+"+"\(faxnumber)")
                                                
                                        })
                                        alert.addAction(close)
                                        alert.addAction(share)
                                        UIApplication.topViewController()!.present(alert, animated: true, completion: nil)
                                    })
                                }
                            }
                        }
                        else
                        {
                            hideLoadingAlertWithComplition {
                                if let value = json["ErrorDescrition"] as? String
                                {
                                    alertview(title: PURCHASE_SUCCESS_TITLE, message: value, UIApplication.topViewController()!)
                                }
                                else
                                {
                                    alertview(title: PURCHASE_SUCCESS_TITLE, message: value, UIApplication.topViewController()!)
                                }
                                
                            }
                        }
                    }
                    else
                    {
                        hideLoadingAlertWithComplition {
                            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                        }
                    }
                }
                else
                {
                    if jsonDictionary.value(forKey: "AutoRenew") == nil
                    {
                        
                        let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", jsonDictionary.value(forKey: "FamilyProduct") as! CVarArg, jsonDictionary.value(forKey: "amount") as! CVarArg, jsonDictionary.value(forKey: "pay_type") as! CVarArg)
                        DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                        hideLoadingAlertWithComplition {
                            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                        }
                        return
                    }
                    else
                    {
                        hideLoadingAlertWithComplition {
                            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                        }
                    }
                }
            }
            else
            {
                hideLoadingAlertWithComplition {
                    alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                }

            }
        }
        catch
        {
//            DLog("json error: \(error)")
            hideLoadingAlertWithComplition {
                alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
            }

        }
    }
    else // Receipt not verified
    {
        hideLoadingAlertWithComplition {
            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
        }
    }
}


// MARK:- Incoming fax file
func getIncomingFaxDocument(inboundObject : Inbound_messages) -> Bool{
    let curentPath = getIncomingPath()?.appendingPathComponent(String(inboundObject.folder_id))
    let faxFilePath = curentPath?.appendingPathComponent(String("MainPage.pdf"))
    if FileManager.default.fileExists(atPath: (faxFilePath?.path)!)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        DLog("file already downloaded")
        return true
    }
    else
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        if !networkAvailability(){
            if let value = UIApplication.topViewController(){
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    alertNetworkNotAvailableTryAgain(controller: value) //LEFT TO REMOVE THE INDICATOR
                }
            }
            return false
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        RunLoop.current.run(until: NSDate().addingTimeInterval(1) as Date)
        let bool = downloadIncommingFaxFile(inboundObject: inboundObject)
        if  bool == true
        {
           return true
        }
        return false
    }
}


func downloadIncommingFaxFile(inboundObject : Inbound_messages) -> Bool{
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
                stopSpinner()
            }
        }
        return false
    }
    
    
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    let postString = "server_id=\(String(inboundObject.server_id))&message_id=\(String(inboundObject.transaction_id))&user_id=\(user_id!)&device_id=\(device_id)"
 
//    DLog("postStrinf : \(postString)")
    let postData = postString.data(using: String.Encoding.utf8)
    let dict = NSMutableDictionary()
    dict.setValue(RECEIVE_FAX_FILE, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    DLog("RECEIVE_FAX_FILE = \(postString)")
    let data : NSData? = appDelegate.sendSynchronousRequestWithParameters(dict, andPostData: postData as NSData?)
    if data != nil
    {
//        DLog("\(String.init(data: (data as! Data), encoding: String.Encoding.utf8)!)")
        
        let incommingPath = getIncomingPath()?.appendingPathComponent(String(inboundObject.folder_id))
        
            do
            {
                try  FileManager.default.createDirectory(at: incommingPath! as URL, withIntermediateDirectories: true, attributes: nil)
                let filePath : URL = incommingPath!.appendingPathComponent("MainPage.pdf")
                let xml = try XML.parse(String.init(data: (data as! Data), encoding: String.Encoding.utf8)!)
                if inboundObject.fax_api == "\(FAX_API_NAME.VITELITY)"
                {
                    if let status = xml["content"]["status"].text, status == "ok"
                    {
                        if let data = xml["content"]["data"].text, data != ""
                        {
                            let decodedata =  NSData.decodeWebSafeBase64(for:data)
                            if  (decodedata as AnyObject).write(to: filePath, atomically: true)
                            {
                                return true
                            }
                            
                        }
                    }
                }
                else if xml["soap"]["soap"]["GetImageChunkEx2Response"]["GetImageChunkEx2Result"]["buffer"].text != nil
                    {
                        if let responsecode = xml["GetImageChunkEx2Result"]["ResultCode"].text, responsecode == "0"
                        {
                
                            if let data = xml["GetImageChunkEx2Result"]["buffer"].text, data != ""
                            {
                                let decodedata =  NSData.decodeWebSafeBase64(for:data)
                                if  (decodedata as AnyObject).write(to: filePath, atomically: true)
                                {
                                    return true
                                }
                            }
                        }
                    }
                else
                {
                    let xmlstring =    String.init(data: (data as! Data), encoding: String.Encoding.utf8)!
                    let fullNameArr = xmlstring.components(separatedBy: "<soap:Body>")
                    do
                    {
                        if fullNameArr.count > 0
                        {
                            let xml = try XML.parse(fullNameArr[1])
                            if let responsecode = xml["GetImageChunkEx2Response"]["GetImageChunkEx2Result"]["ResultCode"].text, responsecode == "0"
                            {
                                if let data = xml["GetImageChunkEx2Response"]["GetImageChunkEx2Result"]["buffer"].text, data != ""
                                {
                                    let decodedata =  NSData.decodeWebSafeBase64(for:data)
                                    if  (decodedata as AnyObject).write(to: filePath, atomically: true)
                                    {
                                        return true
                                    }
                                }
                            }
                        }
                    }
                    catch
                    {
                        
                    }
                 }
            }
            catch
            {
                fatalError("xml parsing issue")
            }
        
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                stopSpinner()
            }
            alertview(title: OOPS_TITLE, message: String.init(data: (data as! Data), encoding: String.Encoding.utf8)!   , value)
        }
    }
    return false
}

func updateSubscriptionPlan(_ dataDict:NSMutableDictionary) -> NSMutableArray{
    
    var dictResponse = NSMutableArray()

    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return dictResponse
    }

    var strUrl = ""
    var webServiceName = ""
    
    if IS_SANDBOX_OR_PRODUCTION_MODE{
        webServiceName = UPDATE_SUBSCRIPTION_CHECK
    }
    else{
        webServiceName = UPDATE_SUBSCRIPTION
    }
    var subscriptionDays = ""
    if let value = dataDict.value(forKey: "sub_plan") as? String{
        subscriptionDays = value
    }
    var user_id = ""
    if let value = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    {
        user_id = value
    }
    var status = ""
    if let value = dataDict.value(forKey: "status") as? String{
        status = value
    }
    
    if isPassPaymentInfo{
        strUrl = String(format:"%@?subscriptionDays=%@&deviceId=%@&parentId=%@&faxNumber=%@&status=%@&userName=%@&bundleId=%@&family_product=%@&iosVersion=%@&newReceipt=%@",webServiceName,subscriptionDays,device_id,user_id,myFaxNumber,UPDATE_DAYS,user_name,BUNDLE_VERSION as! CVarArg,insertPaymentInfo.value(forKey: "family_product") as! CVarArg,OS_NAME_AND_VERSION,"YES")
    }
    else{
       strUrl = String(format:"%@?subscriptionDays=%@&deviceId=%@&parentId%@&faxNumber=%@&status=%@&userName=%@&bundleId=%@&iosVersion=%@&newReceipt=%@",webServiceName,subscriptionDays,device_id,user_id,myFaxNumber,status,user_name,BUNDLE_VERSION as! CVarArg,UIDevice.current.systemVersion,"YES")
    }
    
    let dict = NSMutableDictionary()
    dict.setValue(strUrl, forKey: "url")
    dict.setValue(REQUEST_METHOD_GET, forKey: "req_method")
//    DLog("Request : update Subscription Plan -> \(dict)")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: nil)
//    DLog("\(data)")
    if data != nil
    {
        if status == K_CALCULATE_REAMINING_DAYS
        {
            let reader : XMLReader = XMLReader()
            reader.rootName = "RemainingDays"
            let responseArray:[Any] = reader.parseXMLWithData(data as! Data) as [Any]
//            DLog("Response-->\(responseArray)")
            dictResponse = NSMutableArray(array: responseArray)
        }
    }
    else{
//        DLog("updateSubscriptionPlan  Data Comes Nil")
    }
    return dictResponse
 
}

func continueSetupFeePaymentProcess(){
    let dict = NSMutableDictionary()
    dict.setValue(insertPaymentInfo.value(forKey: "sub_type"), forKey: "sub_type")
    dict.setValue(insertPaymentInfo.value(forKey: "isd_code"), forKey: "isd_code")
    dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "family_product")
//    dict.setValue(RECEIPT_DATA, forKey: "receipt_string")
    sendInboundFaxPaymentToServer_SubscptnPlan(dict)
    if UserDefaults.standard.value(forKey:IS_CONTINUE_TRANSACTION) as! String == "1"{
        
        getAutoRenewProduct_group(group: insertPaymentInfo.value(forKey: "product_group") as! String?, duration: insertPaymentInfo.value(forKey: "product_duration") as! String?)
        insertPaymentInfo.setValue(autorenewProduct, forKey: "family_product")
        if autorenewProduct == "limit_exceed"
        {
            if let value = UIApplication.topViewController()
            {
                alertview(title: TITLE_LIMIT_EXCEED, message: PURCHASED_MANY_NO, value)
            }
        }
        else
        {
            payAndSubscribeSubscptnPaymentType(paymentType: PAYMENT_TYPE.MONTHLY_FEE.rawValue)
        }
    }
    else
    {
        if let value = UIApplication.topViewController()
        {
            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, value)
        }
    }
}

func sendSetupFeeDataToServer(_ dataDict: NSMutableDictionary){
    
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SEND_SETUP_FEE_DATA_TO_SERVER])
    trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_FAXNUMBER,GA_ACTION:SEND_SETUP_FEE_DATA_TO_SERVER])

//    DLog("datadict = \(dataDict)")
    let dict = NSMutableDictionary()
    dict.setValue(FAX_SETUP_PAYMENT, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
    
    let jsonData =  try! JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted)
    let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as NSString
    let params = String(format:"Data=[%@]",jsonString)
    
//    DLog("FAX_SETUP_PAYMENT  Request : fax setup payment -> \(dict) \(params)  ")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
//    DLog("\(NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue))")
    if data != nil
    {
        do
        {
            let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//            DLog("FAX_SETUP_PAYMENT  Response fax setup payment: \(json)" )
            if let value = json["receipt_response"] as? String{
                if value == "YES"
                {
//                    DLog("Successfully  fax setup payment to server")
                    let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", dataDict.value(forKey: "FamilyProduct") as! CVarArg, dataDict.value(forKey: "amount") as! CVarArg, dataDict.value(forKey: "pay_type") as! CVarArg)
                    DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                    
                    // Remains: timerForPurchase timer handle
                    
                    if let value = json["ID"] as? NSNumber{
                        GetIDFromSubinserAction = "\(value)"
                    }

                    dataDict.setValue(GetIDFromSubinserAction, forKey: "id")
                    setValueInUserDefault(key: PAYMENT_INFO_FIRSTTIME_SETUP_TRANSACTION, value: dataDict,isSync: true)
                }
                else // Receipt Not Vierified
                {
                    let predicateValue = NSPredicate (format: "product_name = %@ AND amount = %@ AND transaction_type = %@", dataDict.value(forKey: "FamilyProduct") as! CVarArg, dataDict.value(forKey: "amount") as! CVarArg, dataDict.value(forKey: "pay_type") as! CVarArg)
                    DataModel.sharedInstance.deleteInboundTransction(predicateValue)
                    setValueInUserDefault(key: IS_CONTINUE_TRANSACTION, value: "0",isSync: true)
                    removeValueFromUserDefault(key: PAYMENT_INFO_FIRSTTIME_SETUP_TRANSACTION,isSync:true)
                    hideLoadingAlertWithComplition {
                        alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
                    }
                    
                    return
                }
            }
            
        }
        catch
        {
//            DLog("json error: \(error)")
            CallIFtblUserRecordFound()
            hideLoadingAlertWithComplition {
                alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
            }
            return
        }
    }
    else{
        CallIFtblUserRecordFound()
        hideLoadingAlertWithComplition {
            alertview(title: PURCHASE_SUCCESS_TITLE, message: CONTACT_SUPPORT_TEAM1, UIApplication.topViewController()!)
        }
        return
    }

}

func ActinsheetForIOS78(_ viewController:UIViewController){
    let alertController = UIAlertController(title: LOGIN_LABEL, message: MSG_NUMBER_PURHCASE, preferredStyle: .alert)
    let ok = UIAlertAction(title: CONTINUE_BTN, style: .default, handler: { (action) -> Void in
        isForceLogin = true
        forceLoginFrom =  FORCE_LOGIN_TYPE.MONTHLY_FEE_LOGIN.rawValue
        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:MONTHLY_FEE_PURCHASING])
        trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_FAXNUMBER,GA_ACTION:MONTHLY_FEE_PURCHASING])

        if let value = UIApplication.topViewController(){
            let vc = value.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            vc.hidesBottomBarWhenPushed = true
            isForceLogin = true
            vc.isFromFaxnumber = true
            value.navigationController?.pushViewController(vc, animated: true)
        }
    })
    alertController.addAction(ok)
    
    viewController.present(alertController, animated: true, completion: nil)
}

func LoginExtendAlert(){
    // Remains: coding
}

func CallIFtblUserRecordFound(){
    // Remains: coding
}

func SuccessfaxnumberDelay()
{
    var first_time_setup = false
    let dict = prepareInbFaxDict[0] as! Dictionary<String,Any>
//    DLog("\(dict)")
    if let value = dict["first_time_setup"] as? String{
        if value == "FALSE"{
            first_time_setup = true
        }
    }
    if trialMode == true && (insertPaymentInfo.value(forKey: "isd_code") as? String) == "US" && first_time_setup
    {
        let dict = NSMutableDictionary()
        dict.setValue(insertPaymentInfo.value(forKey: "sub_type"), forKey: "sub_type")
        dict.setValue(insertPaymentInfo.value(forKey: "isd_code"), forKey: "isd_code")
        dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "family_product")
        sendInboundFaxPaymentToServer_SubscptnPlan(dict)
    }
    else
    {
        getAutoRenewProduct_group(group: insertPaymentInfo.value(forKey: "product_group") as! String?, duration: insertPaymentInfo.value(forKey: "product_duration") as! String?)
         insertPaymentInfo.setValue(autorenewProduct, forKey: "family_product")
        
        if autorenewProduct == "limit_exceed"
        {
            if let value = UIApplication.topViewController()
            {
                alertview(title: TITLE_LIMIT_EXCEED, message: PURCHASED_MANY_NO, value)
            }
        }
        else
        {
            payAndSubscribeSubscptnPaymentType(paymentType: PAYMENT_TYPE.MONTHLY_FEE.rawValue)
        }
    }
}

func forceLogout()
{
    afterLogoutCleanDetails()
    
    DispatchQueue.main.async {
        alertviewForLogoutComplete(title: FORCE_LOGOUT_TITLE, message: FORCE_LOGOUT_MESSAGE, UIApplication.topViewController()!)
    }
}

func afterLogoutCleanDetails()
{
    
    removeValueFromUserDefault(key: DEFAULT_USERID,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_DEVICECOUNT,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_CREDIT_COUNT,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_EMAIL_NOTIFICATION,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_CURRENT_EMAILID,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_PROMO_CODE,isSync:false)
    removeValueFromUserDefault(key: DEFAULT_USERLOGIEDIN,isSync:true)
    removeValueFromUserDefault(key: DEFAULT_FAX_NUMBERS,isSync:true)
    removeValueFromUserDefault(key: DEFAULT_INCOMMING_COLLECTION_RELOAD,isSync:true)
    faxnumbers.removeAll()
    DataModel.sharedInstance.removeAllInBoundDataFromDatabase()
}

func loginSignupSuccessfullyFor()
{
    if forceLoginFrom == FORCE_LOGIN_TYPE.SEND_FAX_CREDIT_LOGIN.rawValue
    {
        if isForceLogin
        {
            wizardController?.outboundEntity?.server_id = 0
        }
        isForceLogin = false
        forceLoginFrom = -1
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.darkGray)

        sendOutboudFaxPaymentData(status: RECEIPT_VERIFIED)
    }
    else  if forceLoginFrom == FORCE_LOGIN_TYPE.SEND_FAX_LOW_CREDIT_LOGIN.rawValue
    {
        forceLoginFrom = -1
        isForceLogin = false
        
        wizardController?.sendButtonTapped(UIBarButtonItem())
    }
    else  if forceLoginFrom == FORCE_LOGIN_TYPE.RESEND_FAX_LOW_CREDIT_LOGIN.rawValue
    {
        forceLoginFrom = -1
        isForceLogin = false
        
        if localID != ""
        {
            let pKey = Int(localID)
            if pKey != nil
            {
                let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(pKey!)
                if outboundMessages.count > 0{
                    let outboundEntity = outboundMessages[0]
                    prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue,outboundEntity: outboundEntity)
                }
                localID = ""
            }
        }
    }
    else if forceLoginFrom == FORCE_LOGIN_TYPE.EDIT_SEND_FAX_LOW_CREDIT_LOGIN.rawValue
    {
        forceLoginFrom = -1
        isForceLogin = false
        wizardController?.sendFAxAfterValidation()
    }
    else if forceLoginFrom == FORCE_LOGIN_TYPE.MONTHLY_FEE_LOGIN.rawValue{
        forceLoginFrom = -1
        isForceLogin = false
        if  UIApplication.topViewController() is FaxNumberViewController{
                let FN = UIApplication.topViewController() as! FaxNumberViewController
                FN.set_indicator()
        }
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.darkGray)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        if trialMode == true && ((insertPaymentInfo.value(forKey: "isd_code") as? String) == "US")
        {
            let dict = NSMutableDictionary()
            dict.setValue(insertPaymentInfo.value(forKey: "sub_type"), forKey: "sub_type")
            dict.setValue(insertPaymentInfo.value(forKey: "isd_code"), forKey: "isd_code")
            dict.setValue(insertPaymentInfo.value(forKey: "family_product"), forKey: "family_product")
    
            sendInboundFaxPaymentToServer_SubscptnPlan(dict)
        }
        else
        {
            SuccessfaxnumberDelay()
        }
    }
    else if forceLoginFrom == FORCE_LOGIN_TYPE.SETUP_FEE_LOGIN.rawValue{
        forceLoginFrom = -1
        isForceLogin = false
        if  UIApplication.topViewController() is FaxNumberViewController{
            let FN = UIApplication.topViewController() as! FaxNumberViewController
            FN.set_indicator()
        }
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.darkGray)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        continueSetupFeePaymentProcess()
    }
    else if forceLoginFrom == FORCE_LOGIN_TYPE.BUY_FAX_CREDIT_LOGIN.rawValue
    {
        forceLoginFrom = -1
        isForceLogin = false
        startSpinner(type: NORMAL_SPINNER, message: "", networkIndicator: true, color:UIColor.darkGray)
        addUserCredit(status: RECEIPT_VERIFIED)
    }
}

// MARK:- AttachementOption
func pressScanImageOption(fromViewController : UIViewController)
{
    if  UIImagePickerController.isSourceTypeAvailable(.camera)
    {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus
        {
        case .denied:
            alertview(title: INFORMATION_TITLE, message: PLEASE_TURN_ON_MSG, UIApplication.topViewController()!)
            break
        case .authorized:
           
            let scanner = IRLScannerViewController.standardCameraView(with: fromViewController as! IRLScannerViewControllerDelegate)
            scanner.showControls = true
            scanner.showAutoFocusWhiteRectangle = true
            hideLoadingAlertWithPresentController(viewcontroller: scanner)
 
            break
        case .restricted:
            alertview(title: INFORMATION_TITLE, message: PLEASE_TURN_ON_MSG, UIApplication.topViewController()!)
            
            break
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                if granted
                {
//                    print("Granted access to \(cameraMediaType)")
                    let scanner = IRLScannerViewController.standardCameraView(with: fromViewController as! IRLScannerViewControllerDelegate)
                    scanner.showControls = true
                    scanner.showAutoFocusWhiteRectangle = true
                    hideLoadingAlertWithPresentController(viewcontroller: scanner)
                    
                    //UIApplication.topViewController()?.present(scanner, animated: true, completion: nil)
                }
                else
                {
//                    print("Denied access to \(cameraMediaType)")
                    alertview(title: INFORMATION_TITLE, message: PLEASE_TURN_ON_MSG, UIApplication.topViewController()!)
                }
            }
        }
    }
}


// MARK:- Redirect Screen

//Go to Draft Screen
func goToDraftScreen()
{
    if let value = UIApplication.topViewController() {
        value.dismiss(animated: true, completion: { 
            let vc = storyboard.instantiateViewController(withIdentifier: "DraftViewController") as! DraftViewController
            UIApplication.topViewController()!.present(vc, animated: true, completion: nil)
        })
    }
}

//  Go to Wizard Screen
func goToWizardScreen()
{
        let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
        vc.outboundEntity = nil
        hideLoadingAlertWithPresentController(viewcontroller: vc)
}

//Go to Rate Screen
func goToRateScreen(){
    if  UIApplication.topViewController()! is RatingViewController
    {
        UIApplication.topViewController()!.dismiss(animated: true, completion: {
            let vc = storyboard.instantiateViewController(withIdentifier: "RatingViewController") as! RatingViewController
            vc.providesPresentationContextTransitionStyle = true
            vc.definesPresentationContext = true
            UIApplication.topViewController()?.tabBarController?.present(vc, animated: true, completion: nil)

        })
    }
    else
    {
        let vc = storyboard.instantiateViewController(withIdentifier: "RatingViewController") as! RatingViewController
        vc.providesPresentationContextTransitionStyle = true
        vc.definesPresentationContext = true
        UIApplication.topViewController()?.tabBarController?.present(vc, animated: true, completion: nil)

    }
}

// MARK:- Extension

extension UIButton {
    func startGlowingAnimation(_ isOn : Bool) {
        if (isOn) {
            let labelTransparency :CGFloat = 0.5
            let labelWidth:CGFloat = self.frame.size.width
            
            let glowSize :CGFloat = 40 / labelWidth
            
            let startingLocations :NSArray = [NSNumber.init(value: 0.0 as Float), NSNumber.init(value: ((Float)(glowSize / 2)) as Float),NSNumber.init(value: ((Float)(glowSize)/1) as Float)]
            
            let endingLocations = [(1.0 - glowSize), (1.0 - (glowSize / 2)), 1.0] as NSArray
            
            let animation :CABasicAnimation = CABasicAnimation(keyPath: "locations")
            let glowMask:CAGradientLayer = CAGradientLayer.init()
            glowMask.frame = self.bounds
            
            let gradient = UIColor.init(white: 0.5, alpha: labelTransparency)
            glowMask.colors =  [gradient.cgColor, UIColor.white.cgColor, gradient.cgColor]
            glowMask.locations = startingLocations as? [NSNumber]
            glowMask.startPoint = CGPoint(x: 0 - (glowSize * 2), y: 1)
            glowMask.endPoint = CGPoint(x: 1 + glowSize , y: 1)
            self.titleLabel?.layer.mask = glowMask
            
            animation.fromValue = startingLocations
            animation.toValue = endingLocations
            animation.repeatCount = Float.infinity
            animation.duration = 2.5
            animation.isRemovedOnCompletion = false
            glowMask.add(animation, forKey: "gradientAnimation")
        }
        else {
            let mask = self.titleLabel?.layer.mask as! CAGradientLayer
            mask.colors =  [UIColor.black.cgColor,UIColor.black.cgColor,UIColor.black.cgColor]
            self.titleLabel?.layer.mask?.removeAnimation(forKey: "gradientAnimation")
        }
    }
}

extension UIViewController {
    var previousViewController: UIViewController? {
        guard let controllers = navigationController?.viewControllers, controllers.count > 1 else { return nil }
        switch controllers.count {
        case 2: return controllers.first
        default: return controllers.dropLast(2).first
        }
    }
}

extension String {
    // Fax number formate
        func parsePhonenumber() -> Bool
        {
        do
        {
            let phoneNumberCustomDefaultRegion = try phoneNumberKit.parse(self, withRegion: "GB", ignoreType: true)
            return true
        }
        catch
        {
            print("Generic parser error")
            return false
        }
        
    }
    
    var formatFaxNumber: String! {
        var localFax = self
        
        if localFax.characters.first != "+"
        {
            localFax = "+" + localFax
        }
        
        //US-CANADA +1 (212) 123-1234
        do {
            let phoneNumber = try phoneNumberKit.parse(localFax)
            localFax =   phoneNumberKit.format(phoneNumber, toType: .international)
        }
        catch {
            print("Generic parser error")
        }
        
        return localFax
    }
    
    // Get hieght and width from text and font
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
    
    func widthWithConstrainedHeight(height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.width
    }
    //////////
    
    func isEmail() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]+$", options: NSRegularExpression.Options.caseInsensitive)
            return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
        } catch { return false }
    }

    func insert(string:String,ind:Int) -> String {
        return  String(self.characters.prefix(ind)) + string + String(self.characters.suffix(self.characters.count-ind))
    }
    
    var md5: String! {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str!, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate(capacity: digestLen)
        return String(format: hash as String)
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
extension NSMutableDictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            //            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            //            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedKey = (key as! String).addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            let percentEscapedValue = (value as! String).addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            
            return "\(percentEscapedKey)=\(percentEscapedValue)" as String
        }
        return parameterArray.joined(separator: "&")
    }
}

// MARK:- Enumeration
enum COUNTRY_PIKER_TYPES: String {
    case WIZARD_COUNTRY_PIKER = "TerritoryName"
    case FAXNUMBER_COUNTRY_PIKER = "country_name"
}

enum FAX_API_NAME: String{
    case VITELITY = "VITELITY"
    case INTERFAX = "INTERFAX"
}

enum FAX_STATUS: Int {
    case UNPAID_UNSENT = 1, PAID_UNSENT = 2, SENDING = 3, RECEIVED_FAX = 4, RECEIVED = 99, SENT = 5
}

enum PAYMENT_OPTION {
    case CREDIT, ITUNES, PAYPAL
}

enum PAYMENT_TYPE: Int {
    case CREDIT, EXTEND_NUMBER, MONTHLY_FEE, SEND_FAX, SETUP_FEE, READ_PAGE_LIMIT
}

enum TRANSACTION_BY: String{
    case CREDIT = "iOS_Credit"
    case iTUNES = "iOS_iAP"
    case PAYPAL = "iOS_PayPal"
}

enum SEND_FAX_MODE: Int {
    case NEW_FAX, EDITED_FAX, RESESND_FAX
}

enum SYNC_DATA: Int {
    case CREDIT_PACKAGE, INBOUND_FAX, OUTBOUND_FAX
}

enum TRANSACTIONS_TYPE: String {
    case INBOUNT_FIRST      = "1TIMESETUPFEE"
    case INBOUNT_MONTHLY    = "Auto_new_number"
    case INBOUNT_EXCEED     = "Auto_renew_number"
    case SEND_FAX           = "Fax_sent"
}

enum FORCE_LOGIN_TYPE: Int {
    case SEND_FAX_CREDIT_LOGIN, SEND_FAX_LOW_CREDIT_LOGIN, MONTHLY_FEE_LOGIN, SETUP_FEE_LOGIN, BUY_FAX_CREDIT_LOGIN ,RESEND_FAX_LOW_CREDIT_LOGIN,EDIT_SEND_FAX_LOW_CREDIT_LOGIN
}


// MARK:- Get and Set NSUSERDEFAULT

func setValueInUserDefault(key:String,value:Any,isSync:Bool){
    UserDefaults.standard.set(value, forKey: key)
    if isSync == true
    {
        UserDefaults.standard.synchronize()
    }
}

func getValueFromUserDefault(key:String) -> Any{
    return UserDefaults.standard.value(forKey: key) as Any
}

func removeValueFromUserDefault(key:String,isSync:Bool){
    UserDefaults.standard.removeObject(forKey:key)
    if isSync == true
    {
        UserDefaults.standard.synchronize()
    }
}

func getUserFaxNumbers()
{
    if !networkAvailability()
    {
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    let varsion = OS_NAME_AND_VERSION.replacingOccurrences(of: " ", with: "")
    let params = String(format:"%@?deviceId=%@&os=%@&parentId=%@" , arguments: [PURCHASED_FAX_NUMBER_LIST,device_id,varsion,user_id!])
    
    let dict = NSMutableDictionary()
    dict.setValue(params, forKey: "url")
    dict.setValue(REQUEST_METHOD_GET, forKey: "req_method")
    DLog("Request : Check fax number availibility -> \(dict)  \(params)")
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: nil)
    if data != nil
    {
        let responce  : NSString = NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue)!
        DLog("getUserFaxNumbers  Response :")
        
        let reader : XMLReader = XMLReader()
        reader.rootName = "Faxdetails"
        
        let responseArray:[AnyObject] = reader.parseXMLWithData(data as! Data) as [AnyObject]
        faxnumbers = responseArray as! [Dictionary<String, Any>]
//        DLog("Check fax number availibility Response-->\(responseArray)")
        for index in 0 ..< responseArray.count
        {
            var recordData:[String:Any] = [:]
            recordData = responseArray[index] as! Dictionary<String, Any>
            user_name = recordData["username"] as! String
        }
        faxnumbers = responseArray as! [Dictionary<String, Any>]
        setValueInUserDefault(key: DEFAULT_FAX_NUMBERS, value: faxnumbers, isSync: true)
        AppDelegate().getFax()
        DispatchQueue.main.async {
            if let value = UIApplication.topViewController(){
                if value is HomeViewController
                {
                    let HC = value as! HomeViewController
                    HC.faxNumberBtton_Update()
                }
            }
        }
    }
}

//MARK: Method to get images by Country Name
func getImageFilename(_ TerritoryCode: String) -> String {
    
    var imageFilename = TerritoryCode + ".png"
    
    if TerritoryCode == "SP"
    {
        imageFilename = "ES.png"
    }
    else if TerritoryCode == "70" || TerritoryCode == "07" || TerritoryCode == "44" || TerritoryCode == "45" || TerritoryCode == "87" || TerritoryCode == "71" || TerritoryCode == "72" || TerritoryCode == "09"
    {
        imageFilename = "GB.png"
    }
    else if TerritoryCode == "F8"
    {
        imageFilename = "FR.png"
    }
    else if TerritoryCode == "81" || TerritoryCode == "82" || TerritoryCode == "83" || TerritoryCode == "84" || TerritoryCode == "85" || TerritoryCode == "00"
    {
        imageFilename = "DE.png"
    }
    else if TerritoryCode == "HI" || TerritoryCode == "ZZ" || TerritoryCode == "AA" || TerritoryCode == "ZX" || TerritoryCode == "N1" || TerritoryCode == "N2" || TerritoryCode == "N3" || TerritoryCode == "N4" || TerritoryCode == "01" || TerritoryCode == "02"
    {
        imageFilename = "NoFlag.png"
    }
        //temp : Remove after getting flag image
    else if TerritoryCode == "AQ" || TerritoryCode == "YU" || TerritoryCode == "me" || TerritoryCode == "AN" || TerritoryCode == "EH" || TerritoryCode == "SH"
    {
        imageFilename = "NoFlag.png"
    }
        //
    else
    {
        imageFilename = TerritoryCode + ".png"
    }
    
    return imageFilename
}

func getPrefixFromCode(_ TerritoryCode : String, countryDic : NSMutableDictionary) -> Int
{
    let countryPrefix = countryDic["Prefix"] as! Int
    return countryPrefix
}

//MARK: inBoundPrice & Country List
func inBoundPrice(isoCode : String)
{
    
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    Inbound_State_Prices = []
    let OSVersion = UIDevice.current.systemVersion
    var params = ""
    if isoCode != ""
    {
        params = String(format:"country_isocode=%@&user_id=%@&device_id=%@&country_locale=%@&os=%@" , arguments: [isoCode,"",device_id,countryCode,OSVersion])

    }
    else
    {
        var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if user_id == nil
        {
            user_id = ""
        }
        params = String(format:"user_id=%@&device_id=%@" , arguments: [user_id!,device_id])
    }
    
    let dict = NSMutableDictionary()
    dict.setValue(GET_INBOUND_PRICES, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
//    DLog("Request : Inbound Country PriceList -> \(dict)  \(params)")
    
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
        // (dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
        if data != nil
        {
            do
            {
                let inBoundPriceList = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//                  DLog("inBoundPrice Response : \(inBoundPriceList)" )
                if inBoundPriceList["status"]! as! String == "1"
                {
                    if isoCode  == ""
                    {
                        contry_Array = inBoundPriceList["data"] as! [AnyObject]
                    }
                    else
                    {
                        Inbound_State_Prices = inBoundPriceList["data"] as! [AnyObject]
                        hideLoadingAlert()
                    }
                }
                else if inBoundPriceList["status"]as!  String != "1"
                {
                    alertview(title: ALERT_TITLE, message: MAX_LOGIN_WARNING, UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController)!)
                }
                else{
                    alertview(title: TITLE_CONNECTION_LOST, message: RQST_TIMES_OUT_MSG, UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController)!)
                    
                }
            }catch {
//                DLog("Error with Json: \(error)")
                hideLoadingAlert()
                }
        }
}

//MARK: CHECK RATE SUCCESS.
func showRateAlertOrNot () -> Bool{
    var rateCount = getValueFromUserDefault(key: DEFAULT_RATING_COUNT) as? Int
    let isNoThanks = getValueFromUserDefault(key: DEFAULT_RATING_NO) as? Bool
    if isNoThanks == nil || isNoThanks! {
        if (rateCount == nil || rateCount!%5 == 0)
        {
            rateCount = 0
            rateCount! += 1
            setValueInUserDefault(key: DEFAULT_RATING_COUNT, value: rateCount!,isSync: true)
            return true
        }
        else
        {
            rateCount! += 1
            setValueInUserDefault(key: DEFAULT_RATING_COUNT, value: rateCount!,isSync: true)
        }
    }
    return false
}

func getAllFiles(_ outBoundMsg : Outbound_messages) -> [URL]
{
        var files = [URL]()

        let attechedFiles = DataModel.sharedInstance.getAllAttechmentFileList(entityObject: outBoundMsg)
        if outBoundMsg.is_cover_on == true
        {
            let path = getCoverPagePath(Int(outBoundMsg.folder_id), outBoundMsg: outBoundMsg)
            files.append(path)
        }
        for i in 0..<attechedFiles.count
        {
            let file : URL = attechedFiles[i]
            if validDropDocument(file.lastPathComponent){
                if !file.lastPathComponent.hasPrefix("MainPage_"){
                    files.append(file)
//                    self.lbl_addCOverWang.isHidden = true
                    
                }
            }
        }
    //        let outBoundMsg = outboundListFiltered[index] as Outbound_messages
//    let folder_id = outBoundMsg.folder_id
   
//        let PDFfiles = generatePDF(Int(folder_id), outBoundMsg: outBoundMsg)
//        files.append(contentsOf: PDFfiles)
    return files
}

func generatePDF(_ index : Int, outBoundMsg : Outbound_messages) -> [URL]
{
    let localDirectory = getOutgoingPath()
    let folderPath = localDirectory?.appendingPathComponent("\(index)")
//    DLog("folderPath: \(folderPath)")
    
    //        let outboundMsg = outboundListFiltered[selectedRow] as Outbound_messages
    var filePath = [URL]()
    if let filesSet = outBoundMsg.files{
        let files = filesSet.allObjects as! [Outbound_message_files]
        
        for object in files as [Outbound_message_files]
        {
//            DLog("fileName: \(object.file_name)--")
            let path = folderPath?.appendingPathComponent(object.file_name!)
//            DLog("folderPath: \(path)")

            filePath.append(path!)
        }
        
        outBoundMsg.files = NSSet(array: files)
//        DLog("outboundEntity?.files: \(outBoundMsg.files)")
        return filePath
    }
    else
    {
        return []
    }
}

//MARK: For generating PDF

func getCoverPagePath(_ index : Int, outBoundMsg : Outbound_messages) -> URL
{
//    DLog("index: \(index)")
    let localDirectory = getOutgoingPath()
    let folderPath = localDirectory?.appendingPathComponent("\(index)")
    let coverPath = folderPath?.appendingPathComponent(COVER_FOLDER)
    
    //        let outboundMsg = outboundListFiltered[selectedRow] as Outbound_messages
    var fileURL : URL = URL(fileURLWithPath: "")
    
    if let value = Int64("\(outBoundMsg.template_no)")
    {
        fileURL = (coverPath?.appendingPathComponent("MainPage_\(value).pdf"))!
    }
    return fileURL
}

//MARK: PriceList For OutBound Country

func OutBound_priceListChart(country_code:String , viewContriller : UIViewController)
{
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }

//    let  auth_key : String = md5(string: UNIQUE_ID)
    //        dc013cc0c704974f8bcdf5451ef094c1
//    let OSVersion = UIDevice.current.systemVersion
    
    let params = "country_id=\(country_code)&unique_id=\(AUTH_KEY_IFAX.md5!)&user_id=\(user_id!)&os=\(OS_NAME_AND_VERSION)&device_id=\(device_id)"

//    let params = String(format:"country_id=%@&%@=%@&user_id=%@&device_id=%@&os=%@" , arguments: [country_code,AUTH_TOKEN,auth_key,"" as CVarArg,device_id,OSVersion])
    
    let dict = NSMutableDictionary()
    dict.setValue(GET_CREDIT_PRICE_CHART, forKey: "url")
    
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
//    DLog("Request : Inbound Country PriceList -> \(dict)  \(params)")
    
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }

    
    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    if data != nil
    {
        do
        {
            outBoundPriceList = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//            DLog("Response : \(outBoundPriceList)" )
            
            if outBoundPriceList["status"]! as! String == "1"
            {
                outBoundPriceChart  = outBoundPriceList["data"] as! [AnyObject]
                var  productListArr : [String] = []
                UserDefaults.standard.set(outBoundPriceList, forKey: "outBoundPriceList")

                for i in 0..<outBoundPriceChart.count
                {
                    productListArr.append(outBoundPriceChart[i].object(forKey: "product_name") as! String)
                }
                ChekcingPriceInbOrObnd = 5
                let productSet : Set = Set(productListArr)
                let pList : NSMutableArray = NSMutableArray(array: productListArr)
                
                StoreKitHelper.sharedInstance.currentController = viewContriller
                if country_code == DefaultCountryID
                {
                    StoreKitHelper.sharedInstance.str_DefaultCountry = country_code
                }
                else {
                     StoreKitHelper.sharedInstance.str_DefaultCountry = ""
                }
//                DLog("productSet = \(productSet)")
                StoreKitHelper.sharedInstance.requestProductData(productIds: productSet, productOrderedList: pList,viewController: nil)
            }
           else{
                alertview(title: TITLE_CONNECTION_LOST, message: RQST_TIMES_OUT_MSG,viewContriller)
            }
        }catch {
//            DLog("Error with Json: \(error)")
            alertview(title: TITLE_CONNECTION_LOST, message: RQST_TIMES_OUT_MSG, viewContriller)
        }
    }
    else {
        hideLoadingAlert()
    }
    
}


//MARK: SHOW BADGE

func showBadge (){
    DispatchQueue.global(qos: .background).async {
        let count = DataModel.sharedInstance.getUnPaidUnsentFaxCount()
        DispatchQueue.main.async {
            if count == 0{
                UIApplication.topViewController()?.tabBarController?.tabBar.items?[1].badgeValue = nil
            }
            else
            {
                UIApplication.topViewController()?.tabBarController?.tabBar.items?[1].badgeValue = "\(count)"
            }
        }
    }
}

func getDefaultCoverPath() -> URL?
{
    //DLog("name" , String(outboundEntity!.folder_id))
    var isDir : ObjCBool = false
    let documentsPath = getPathURLOfContainer()
    let logsPath = documentsPath?.appendingPathComponent("DefaultCover")
    do
    {
        if FileManager.default.fileExists(atPath:(logsPath?.path)!, isDirectory:&isDir)
        {
            return logsPath
        }
        else
        {
            try FileManager.default.createDirectory(atPath : (logsPath?.path)!, withIntermediateDirectories:  true, attributes: nil)
        }
    }
    catch let error as NSError
    {
//        DLog("Unable to create directory \(error.debugDescription)")
    }
    return logsPath
}

func redirectToMailApp()
{
    let email = MAIL_IFAXAPP_COM
    let url = NSURL(string: "mailto:\(email)")
    UIApplication.shared.openURL(url as! URL)
}


//MARK: SCHEDULE THE LOCAL NOTIFICATION

func setLocalNotificationForUnpaidDraft (outBoundMsg : Outbound_messages)
{
    let localNotification = getValueFromUserDefault(key: DEFAULT_PUSH_NOTIFICATION) as? Int
    
    if localNotification == 1 || localNotification == nil{
        let lastScheduleDrat = getValueFromUserDefault(key: DEFAULT_LAST_SCHEDULE_DRAFT) as? Int64
        if lastScheduleDrat != outBoundMsg.folder_id
        {
            let notification = UILocalNotification()
            notification.alertBody = DONT_FORGET_TO_SEND_FAX
            notification.alertAction = "open"
            notification.hasAction = true
            notification.userInfo = ["lastFaxFolderID": outBoundMsg.folder_id,"identifier" : "DraftNotification"]
            notification.category = "DraftNotification"
            
            setValueInUserDefault(key: DEFAULT_LAST_SCHEDULE_DRAFT, value: outBoundMsg.folder_id, isSync: true)
            UIApplication.shared.cancelAllLocalNotifications()
            for index in 0...3 {
                let itemDate = Date()
                
                if index == 0{
                    let newDate1 = itemDate.addingTimeInterval(60*60)
                    notification.fireDate = newDate1
                }
                else if index == 1
                {
                    let newDate2 = itemDate.addingTimeInterval((60*60)*3)
                    notification.fireDate = newDate2
                }
                else if index == 3
                {
                    let newDate3 = itemDate.addingTimeInterval(60*60*24)
                    notification.fireDate = newDate3
                }
                else
                {
                    let newDate4 = itemDate.addingTimeInterval((60*60*24)*3)
                    notification.fireDate = newDate4
                }
                UIApplication.shared.scheduleLocalNotification(notification)
            }
            //LOCAL notification
            if #available(iOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert,.badge, .sound]) { (granted, error) in
                    if granted {
                        // later send fax
                        let action1 = UNNotificationAction(identifier: LATER_BTN, title: LATER_BTN, options: [.foreground])
                        // No Thanks Button
                        let action2 = UNNotificationAction(identifier: RATE_NO_THANKS, title: RATE_NO_THANKS, options: [.foreground])
                        
                        let category = UNNotificationCategory(identifier: "DraftNotification", actions: [action1, action2], intentIdentifiers: [], options: [])
                        UNUserNotificationCenter.current().setNotificationCategories([category])
                        
                    } else {
                    }
                }
            }
            else {
                // Fallback on earlier versions
                
                // later send fax
                let action1 = UIMutableUserNotificationAction()
                action1.activationMode = .background
                action1.title = LATER_BTN
                action1.identifier = LATER_BTN
                action1.isDestructive = false
                action1.isAuthenticationRequired = false
                
                // No Thanks Button
                let action2 = UIMutableUserNotificationAction()
                action2.activationMode = .background
                action2.title = RATE_NO_THANKS
                action2.identifier = RATE_NO_THANKS
                action2.isDestructive = false
                action2.isAuthenticationRequired = false
                
                let actionCategory = UIMutableUserNotificationCategory()
                actionCategory.identifier = "DraftNotification"
                actionCategory.setActions([action1, action2], for: .default)
                
                
                let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
                let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: [actionCategory])
                
                 UIApplication.shared.registerUserNotificationSettings(pushNotificationSettings)
            }
        }

    }
}

func forceUpadte(compltion: @escaping ()->())
{
    if networkAvailability(){
        var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if user_id == nil
        {
            user_id = ""
        }
        let params = "version=\(APP_VERSION)&os=iOS+10.0&device_id=\(device_id)&user_id=\(user_id!)&build=\(BUNDLE_VERSION!)"
        let dict = NSMutableDictionary()

        dict.setValue(FORCE_UPDATE ,forKey: "url")
        dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        
        AppDelegate().sendAsynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8
            ), completion: { data in
                if data != nil
                {
                    do
                    {
                        let json = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
                        if json.count > 0
                        {
                            var dictionary : [String:Any] = [:]
                            if json["status"] as! String == "1"
                            {
                                let asrr:[Any] = json["data"] as! [Any]
                                if asrr.count > 0
                                {
                                    for i in 0..<asrr.count
                                    {
                                        let object = asrr[i] as! [String : String]
                                        dictionary[object["version"]!] = asrr[i]
                                    }
                                    iVersion.sharedInstance().appStoreID = UInt(APP_STORE_ID)
                                    iVersion.sharedInstance().remoteVersionsDict = dictionary
                                }
                            }
                        }
                    }catch{
//                        DLog("forced update excuted")
                        compltion()
                    }
                    compltion()
                }
        })
         }
}

func ForceSTopIndicator()
{
    stopSpinner()
    UIApplication.shared.endIgnoringInteractionEvents()
    
    if let value = UIApplication.topViewController()
    {
        if value is WizardViewController
        {
            let WC = value as! WizardViewController
            WC.overlay_Indicator.isHidden = true
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.06))
        }
        else if value is FaxNumberViewController
        {
            let faxVC = value as! FaxNumberViewController
            faxVC.enabeDisableBarButton(bool: true)
            faxVC.pickerView.isUserInteractionEnabled = true
            faxVC.countryView.isUserInteractionEnabled = true
            faxVC.indicatorLayer.isHidden = true
        }
    }
    
    if indicator != nil
    {
        indicator.stopAnimating()
        indicator.removeFromSuperview()
    }
}

func get_priceList()
{
    if (UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) != nil)
    {
        let countryArray = getValueFromUserDefault(key: OUTBOUND_FAX_COUNTRY_LIST) as! NSArray
        for listCountry  in countryArray{
            let dict = listCountry as! NSDictionary
            let TerriCode = dict.value(forKey: "TerritoryCode") as! String
            if TerriCode == countryCode
            {
                DefaultCountryID = dict.value(forKey: "id") as! String
                OutBound_priceListChart(country_code: DefaultCountryID ,viewContriller:  UIApplication.topViewController()!)
                break
            }
        }
    }
    else
    {
        // Default US country Price List
        OutBound_priceListChart(country_code: "119" ,viewContriller:  UIApplication.topViewController()!)
    }

}


func trackDataOnAnalytics(withData dict: [String: String])
{
    
    if let screename = dict[SCREEN_NAME]
    {
    FIRAnalytics.setUserID(device_id)
    let screen_name = screename.lowercased().replacingOccurrences(of: " ", with: "_")
    FIRAnalytics.logEvent(withName: screen_name.lowercased(), parameters: nil)
    }
    if let tracker = GAI.sharedInstance().defaultTracker
    {
        if (dict[GA] != nil)
        {
            if let screename = dict[SCREEN_NAME]
            {
                tracker.set(kGAIScreenName, value: "\(screename)")  
                tracker.send(GAIDictionaryBuilder.createScreenView().set("\(screename)", forKey: GAIFields.customDimension(for: 1)).build()  as [NSObject : AnyObject])
                
            }
        }
    }
    else
    {
        DLog("Google Analytics not configured correctly")
    }
}

func trackEventOnAnalytics(withData dict: [String: String])
{
    if let action =  dict[GA_ACTION]
    {
        FIRAnalytics.setUserID(device_id)
        let screen_name = action.lowercased().replacingOccurrences(of: " ", with: "_")
        FIRAnalytics.logEvent(withName: screen_name.lowercased(), parameters: nil)
    }
    
    if let tracker = GAI.sharedInstance().defaultTracker
    {
        
        if (dict[GA] != nil)
        {
            if let category = dict[GA_CATEGORY],let action =  dict[GA_ACTION]
            {
                tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "\(category)", action: "\(action)", label: "\(action)", value: nil).build() as [NSObject : AnyObject])

                    FIRAnalytics.setUserID(device_id)
                    let screen_name = action.lowercased().replacingOccurrences(of: " ", with: "_")
                    FIRAnalytics.logEvent(withName: screen_name.lowercased(), parameters: nil)
            }
        }
    }
    else
    {
        DLog("Google Analytics not configured correctly")
    }
}

func trackEconomicDataInGA(transactionIdentifier:String ,productIdentifier:String,category:String,revenue:NSNumber,shipping:NSNumber)
{
    if let tracker = GAI.sharedInstance().defaultTracker
    {
        tracker.send(GAIDictionaryBuilder.createTransaction(withId: transactionIdentifier, affiliation: IN_APP_STORE, revenue: revenue, tax: 0, shipping: shipping, currencyCode: GA_CURRENCY_Code).build() as [NSObject : AnyObject])
        
        tracker.send(GAIDictionaryBuilder.createItem(withTransactionId: transactionIdentifier, name: productIdentifier, sku: productIdentifier, category: category, price: revenue, quantity: 1, currencyCode: GA_CURRENCY_Code).build() as [NSObject : AnyObject])
    }
}


func GetinBoundCountryList()
{
    if !networkAvailability(){
        if let value = UIApplication.topViewController(){
            DispatchQueue.main.async {
                alertNetworkNotAvailableTryAgain(controller: value)
            }
        }
        return
    }
    Inbound_State_Prices = []
    
    var params = ""
    let user_id = ""
    params = String(format:"user_id=%@&device_id=%@" , arguments: [user_id,device_id])

    let dict = NSMutableDictionary()
    dict.setValue(GET_INBOUND_PRICES, forKey: "url")
    dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")

    let data : NSData? = AppDelegate().sendSynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    // (dict, andPostData: params.data(using: String.Encoding.utf8)! as NSData?)
    if data != nil
    {
        do
        {
            let inBoundPriceList = try JSONSerialization.jsonObject(with: data as! Data, options:.allowFragments) as! [String : Any]
//            DLog("inBoundPrice Response : \(inBoundPriceList)" )
            if inBoundPriceList["status"]! as! String == "1"
            {
                                   contry_Array = inBoundPriceList["data"] as! [AnyObject]
            }
        }catch {
//            DLog("Error with Json: \(error)")
            hideLoadingAlert()
        }
    }
}

extension UITextField
{
    func checkLength(phoneNumber:Int,string:String) -> Bool
    {
        let aSet = NSCharacterSet(charactersIn:"0123456789 ()-").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
       if  numberFiltered != string || phoneNumber>25
       {
            return false
       }
       else
       {
            return true
       }
    }
    
    func setwhitecolor(country_code:String)
    {
        
        /*
         if let range = self.text?.range(of: country_code)
         {
         let myMutableString = NSMutableAttributedString()
         myMutableString.addAttribute(NSForegroundColorAttributeName,
         value: UIColor.white,
         range: NSMakeRange(0,2))
         self.attributedText = myMutableString
         }
         */
    }
}
func prepareSendFaxDataForServer(mode: Int,outboundEntity:Outbound_messages)
{
    outboundEntity.fax_status = Int64(FAX_STATUS.SENDING.rawValue)
    DataModel.sharedInstance.saveContext()
    let t1 = Int64(FAX_STATUS.SENDING.rawValue)
    if !networkAvailability(){
        isCheckingFaxStatus = false
        if let value = UIApplication.topViewController(){
            alertNetworkNotAvailableTryAgain(controller: value)
        }
        return
    }
    isCheckingFaxStatus = true
    SERVER_ID = ""
    var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
    if user_id == nil
    {
        user_id = ""
    }
    
    let coutnry_id = "\((outboundEntity.country_id))"
    let unique_id = (user_id!.appending(AUTH_KEY_IFAX.md5!)).md5!
    
    let outboundFaxData = NSMutableDictionary()
    outboundFaxData.setValue(BUNDLE_VERSION, forKey: "app_version")
    
    outboundFaxData.setValue(device_id, forKey: "device_id")
    
    var number = ""
    if let c_Code:Int64 = outboundEntity.country_code as Int64?, let f_Number = outboundEntity.fax_number
    {
        number = "+\(c_Code) \(f_Number)" as String
    }
    number = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
    
    outboundFaxData.setValue(number, forKey: "fax_num")
    outboundFaxData.setValue(outboundEntity.folder_id, forKey: "local_id")
    outboundFaxData.setValue(outboundEntity.template_no, forKey: "template_no")
    outboundFaxData.setValue(timeZoneName, forKey: "location")
    outboundFaxData.setValue(OS_NAME_AND_VERSION, forKey: "os")
    if outboundEntity.is_cover_on == false
    {
        outboundFaxData.setValue(0, forKey: "page_count")
        if let counts = outboundEntity.files
        {
            outboundFaxData.setValue(counts.count, forKey: "page_count")
        }
    }
    else
    {
        outboundFaxData.setValue(outboundEntity.files!.count+1, forKey: "page_count")
    }
    outboundFaxData.setValue(outboundEntity.page_count, forKey: "pages")
    outboundFaxData.setValue(outboundEntity.recipient_name, forKey: RECIPIENT_NAME)
    outboundFaxData.setValue(getCurrentLanguageCode(), forKey: "country_locale")
    outboundFaxData.setValue(device_token, forKey: "token")
    outboundFaxData.setValue((unique_id), forKey: "unique_id")
    outboundFaxData.setValue(user_id, forKey: "user_id")
    outboundFaxData.setValue(coutnry_id, forKey: "country_id")
    outboundFaxData.setValue(outboundEntity.is_cover_on, forKey: "isCoverOn")
    outboundFaxData.setValue(outboundEntity.credits, forKey: "requiredCredit")
    
    if  outboundEntity.recipient_email == nil
    {
        outboundFaxData.setValue("", forKey: "recipient_email")
    }
    else
    {
        outboundFaxData.setValue(outboundEntity.recipient_email, forKey: "recipient_email")
    }
    
    if  outboundEntity.transaction_by == nil
    {
        outboundFaxData.setValue("", forKey: "transaction_by")
    }
    else
    {
        outboundFaxData.setValue(outboundEntity.transaction_by, forKey: "transaction_by")
    }
    
    if  outboundEntity.sender_email == nil
    {
        outboundFaxData.setValue("", forKey: "sender_email")
    }
    else
    {
        outboundFaxData.setValue(outboundEntity.sender_email, forKey: "sender_email")
    }
    if  outboundEntity.subject == nil
    {
        outboundFaxData.setValue("", forKey: "subject")
    }
    else
    {
        outboundFaxData.setValue(outboundEntity.subject, forKey: "subject")
    }
    
    let id = (outboundEntity.server_id) as Int64
    if id > 0
    {
        SERVER_ID = "\((id))"
    }
    else
    {
        SERVER_ID = ""
    }
    
    let f_id = (outboundEntity.folder_id) as Int64
    if f_id > 0
    {
        FOLDER_ID = "\((f_id))"
    }
    else
    {
        FOLDER_ID = ""
    }
    
    outboundFaxData.setValue(SERVER_ID, forKey: "server_id")
    if let server_ID =  outboundEntity.server_id  as? Int64
    {
       outboundFaxData.setValue(server_ID, forKey: "server_id")
    }
    
    if !networkAvailability(){
        isCheckingFaxStatus = false
        if let value = UIApplication.topViewController(){
            alertNetworkNotAvailableTryAgain(controller: value)
        }
        return
    }
    outboundEntity.fax_status = Int64(FAX_STATUS.SENDING.rawValue)
    DataModel.sharedInstance.saveContext()
    outboundFaxlistData = outboundEntity
    if mode == SEND_FAX_MODE.NEW_FAX.rawValue || mode == SEND_FAX_MODE.EDITED_FAX.rawValue
    {
        outboundFaxData.setValue(wizardController.AttachementArray, forKey: "attachment_array")
        submitOutboundFaxDataToServer(outboundFaxData: outboundFaxData, mode: mode)
        //            self.backDismiss(compltion:
        //                { _ in
        //                    submitOutboundFaxDataToServer(outboundFaxData: outboundFaxData, mode: mode)
        //            })
        
    }
    else if mode == SEND_FAX_MODE.RESESND_FAX.rawValue
    {
        let attachent:NSMutableArray = []
        
        let attechedFiles = DataModel.sharedInstance.getAllAttechmentFileList(entityObject: outboundEntity)
        for i in 0..<attechedFiles.count
        {
            let file : URL = attechedFiles[i]
            if validDropDocument(file.lastPathComponent){
                if !file.lastPathComponent.hasPrefix("MainPage_"){
                    attachent.add(file)
                }
            }
        }
        
        outboundFaxData.setValue(attachent, forKey: "attachment_array")
        //          submitOutboundFaxDataToServer(outboundFaxData: outboundFaxData, mode: mode)
        
        let id = (outboundEntity.fax_api) as Int64
        if id > 0 && id == 1 && outboundEntity.is_fax_modified == false
        {
            var tran_Id = ""
            let t_id = (outboundEntity.transaction_id) as Int64
            if t_id > 0
            {
                tran_Id = "\((t_id))"
                outboundFaxData.setValue(tran_Id, forKey: "transaction_id")
                resendFaxWithInterFaxAPI(dicoutboudData: outboundFaxData, outboudEntity: outboundEntity)
            }
            else
            {
                tran_Id = ""
                outboundFaxData.setValue(tran_Id, forKey: "transaction_id")
                submitOutboundFaxDataToServer(outboundFaxData: outboundFaxData, mode: mode)
            }
        }
        else
        {
            submitOutboundFaxDataToServer(outboundFaxData: outboundFaxData, mode: mode)
        }
    }
}


extension PhoneNumberTextField
{
    
    func parsePhonenumber(phoneNumber:String) -> Bool
    {
        do
        {
            let phoneNumberCustomDefaultRegion = try phoneNumberKit.parse(phoneNumber, withRegion: "GB", ignoreType: true)
            return true
        }
        catch
        {
            print("Generic parser error")
            return false
        }
        
    }
}

func regoinWiseDateFormate(date:Date)->String
{
    let dateFormatter = DateFormatter()
    let pre = NSLocale.preferredLanguages[0]
    dateFormatter.timeZone = NSTimeZone.system
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    dateFormatter.locale = NSLocale(localeIdentifier: pre) as Locale!
    var convertedDate = ""
    convertedDate = dateFormatter.string(from: date)
    return convertedDate
}



public class Reachabilitys {
    
    class func internetAvaibility() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return isReachable && !needsConnection
    }
}
extension NSMutableArray
{
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}
extension String {
    func indexDistance(of character: Character) -> Int? {
        guard let index = characters.index(of: character) else { return nil }
        return distance(from: startIndex, to:   index)
    }
}
extension OperationQueue {
    
    
    static func debounce(delay: TimeInterval, underlyingQueue: DispatchQueue? = nil, action: @escaping () -> Void) -> (() -> Void) {
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = underlyingQueue
        
        let sleepOpName = "__SleepOp"
        let actionOpName = "__ActionOp"
        
        
        return {
            
            var isExecuting = true
            for op in queue.operations {
                if op.isFinished || op.isCancelled {
                    continue
                }
                
                isExecuting = op.name == actionOpName
                break
            }
            // print("isExecuting: \(isExecuting), count: \(queue.operations.count)")
            if !isExecuting {
                queue.cancelAllOperations()
            }
            
            let sleepOp = BlockOperation(block: {
                Thread.sleep(forTimeInterval: delay)
            })
            sleepOp.name = sleepOpName
            
            let actionOp = BlockOperation(block: {
                action()
            })
            
            actionOp.name = actionOpName
            
            queue.addOperation(sleepOp)
            queue.addOperation(actionOp)
        }
    }
}
