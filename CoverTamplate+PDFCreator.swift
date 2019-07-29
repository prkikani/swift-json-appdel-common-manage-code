

import UIKit
import WebKit
class CoverTamplate_PDFCreator: NSObject {
    static let sharedInstance = CoverTamplate_PDFCreator()
    var keyCallbacks = kCFTypeDictionaryKeyCallBacks
    var valueCallbacks = kCFTypeDictionaryValueCallBacks
    var fieldsDictionary  : NSMutableDictionary = NSMutableDictionary()
    var url : URL!
    var pageRect = CGRect()
    var textFont1 : UIFont!
    var textFont2 : UIFont!
    func renderSingle_CoverTemplate( FetchRequest : Outbound_messages , templte_NO : Int)
    {
        let coverDirectory = CreateDir(DirName: String(FetchRequest.folder_id)).appendingPathComponent(String(format : COVER_FOLDER))
        

        
        do{
            try FileManager.default.createDirectory(at: coverDirectory as URL, withIntermediateDirectories: true, attributes: nil)
                let filePath : URL = coverDirectory.appendingPathComponent(String(format : "MainPage_\(templte_NO).pdf"))
                //                if !FileManager.default.fileExists(atPath: filePath.path){
                self.createPdfWithFaxData(faxObject: FetchRequest , templatesNO : templte_NO , FolderName: String(FetchRequest.folder_id) )
                //                }
                if isThisForiPad == true
                {
                    try UIImageJPEGRepresentation(imageFromPDF(url: url!, targetSize: CGSize(width:1000 ,height: 1024) , PageNo: 1 )!, 2.0)?.write(to: coverDirectory.appendingPathComponent("MainPage_\(templte_NO).png"))
                }
                else
                {
                    try UIImagePNGRepresentation(imageFromPDF(url: filePath, targetSize: CGSize(width:612 ,height: 792) , PageNo: 1 )!)?.write(to: coverDirectory.appendingPathComponent("MainPage_\(templte_NO).png"))
                }
        }catch{}
        stopSpinner()
    }
    
    func renderCoverTemplate( FetchRequest : Outbound_messages)
    {
        DLog("renderCoverTemplate  = \(FetchRequest.folder_id)")
        DLog("renderCoverTemplate CountryCode  =  \(FetchRequest.country_code)")
        let coverDirectory = CreateDir(DirName: String(FetchRequest.folder_id)).appendingPathComponent(String(format : COVER_FOLDER))

        do{
            try FileManager.default.createDirectory(at: coverDirectory as URL, withIntermediateDirectories: true, attributes: nil)
            for i in 0...5
            {
                let filePath : URL = coverDirectory.appendingPathComponent(String(format : "MainPage_\(i).pdf"))
//                if !FileManager.default.fileExists(atPath: filePath.path){
                      self.createPdfWithFaxData(faxObject: FetchRequest , templatesNO : i , FolderName: String(FetchRequest.folder_id) )
//                }
                if isThisForiPad == true
                {
                    try UIImageJPEGRepresentation(imageFromPDF(url: url!, targetSize: CGSize(width:768 ,height: 1024) , PageNo: 1 )!, 2.0)?.write(to: coverDirectory.appendingPathComponent("MainPage_\(i).png"))
                }
                else
                {
                    try UIImagePNGRepresentation(imageFromPDF(url: filePath, targetSize: CGSize(width:612 ,height: 792) , PageNo: 1 )!)?.write(to: coverDirectory.appendingPathComponent("MainPage_\(i).png"))
                }
            }
        }catch{}
        stopSpinner()
    }
    
    func createPdfWithFaxData(faxObject : Outbound_messages , templatesNO : Int ,FolderName : String )
    {
        var xmlFileName : String!
        var imgTemplate : String!
        //var logoRect : CGRect!
        var signRect : CGRect!
        var strChName : String!
        var img_sign : UIImage!
        var FaxtextSize : CGSize!
        var Faxdrawrect : CGRect!
        let path = Bundle.main.path(forResource: "TemplateFormate", ofType: "plist")
        let template_values = NSDictionary(contentsOfFile: path!)
        let documentsDirectory  = getOutgoingPath()?.appendingPathComponent(FolderName).appendingPathComponent(String(format : "cover/MainPage_%d.pdf",templatesNO))
         pageRect  = CGRect(x: 0, y: 0,width:  PDF_MEDIABOX_WIDTH,height:  PDF_MEDIABOX_HEIGHT)
        url  = documentsDirectory!
        let myDictionary : CFMutableDictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks,&valueCallbacks)
        let pdfContext = CGContext (url as CFURL, mediaBox: &pageRect, myDictionary)
        let languageDirection : Locale.LanguageDirection = getLanguageDirection()
        

        strChName = CHECKMARK_IMG
        switch (templatesNO)
        {
            
        case 0:
            xmlFileName = "ClassicTemplate"
            imgTemplate = "pdf_template_classic"
            break
            
        case 1:
            xmlFileName =  "CasualTemplate"
            imgTemplate = "pdf_template_casual"
            
            break
            
        case 2:
            
            xmlFileName = "FunkyTemplate"
            imgTemplate = "pdf_template_funky"
            break
            
        case 3:
            xmlFileName = "MinimalTemplate"
            imgTemplate = "pdf_template_minimal"
            strChName   = "radio-on"
            break
            
        case 4:
            xmlFileName = "ModernTemplate"
            imgTemplate = "pdf_template_modern"
            break
            
        case 5:
            xmlFileName =  "UrbanTemplate"
            imgTemplate = "pdf_template_urban"
            
            break
            
        default:
            break
        }
      
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: RECIPIENT_NAME) as! String, forKey: RECIPIENT_NAME)
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "fax_number") as! String, forKey: "fax_number")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "sender_name") as! String, forKey: "sender_name")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "sender_phone") as! String, forKey: "sender_phone")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "sender_email") as! String, forKey: "sender_email")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "date") as! String, forKey: "date")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "subject") as! String, forKey: "subject")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "pages") as! String, forKey: "pages")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "note_urgent") as! String, forKey: "note_urgent")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "note_reply") as! String, forKey: "note_reply")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "note_review") as! String, forKey: "note_review")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "note_comment") as! String, forKey: "note_comment")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "note_recycle") as! String, forKey: "note_recycle")
        fieldsDictionary.setValue((template_values?.value(forKey: xmlFileName) as! NSDictionary).value(forKey: "comments") as! String, forKey: "comments")

        do{
            ////////Insert text //////
            
            let textStyle1  : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle1.lineBreakMode =  NSLineBreakMode.byWordWrapping
            textStyle1.alignment = NSTextAlignment.left
            textFont1  = UIFont(name: "Helvetica", size: 16)!
            
            
            
            let rect : CGRect  = CGRectFromString(fieldsDictionary.value(forKey: "comments")as! String)
            let textFontAttributes = [NSFontAttributeName: textFont1,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            var myStringSize  : CGSize = CGSize(width : 5 ,height : 5)
            if faxObject.comments != nil
            {
                
                var myString : String = faxObject.comments! as String
                myString = myString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let textView : UITextView  = UITextView(frame: rect)
                textView.typingAttributes = textFontAttributes
                
                textView.insertText(myString)
                myStringSize  = textView.sizeThatFits(rect.size)
                textView.sizeThatFits(rect.size)
            }
            pdfContext?.beginPage (mediaBox: &pageRect)
            UIGraphicsPushContext(pdfContext!)
            
            let context : CGContext = UIGraphicsGetCurrentContext()!
            let pdfRef1 : CGPDFDocument = CGPDFDocument(NSURL.fileURL(withPath: Bundle.main.path(forResource: String(format: "%@", imgTemplate),  ofType: ".pdf")!) as CFURL)!
            
            guard let page = pdfRef1.page(at: 1)else
            {
                return
            }
            pdfContext!.drawPDFPage(page)
            context.translateBy(x: 0,y: CGFloat(PDF_MEDIABOX_HEIGHT))
            context.scaleBy(x: 1.0, y: -1.0)
            
            //MARK: fax_number
            
            if faxObject.country_code != nil
            {
                let number : String =  "+" + String(faxObject.country_code)
                FaxtextSize  = number.size(attributes: textFontAttributes)
                Faxdrawrect  = CGRectFromString(fieldsDictionary.value(forKey: "fax_number")as! String)
                number.draw(in:Faxdrawrect, withAttributes:  self.textAttributes(object: number  , fieldsRect: Faxdrawrect))
                
            }
            if faxObject.fax_number != nil
            {
                let number : String =  "+" + String(faxObject.country_code).appending(" ").appending(faxObject.fax_number!)
                FaxtextSize  = number.size(attributes: textFontAttributes)
                Faxdrawrect  = CGRectFromString(fieldsDictionary.value(forKey: "fax_number")as! String)
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    number.draw(in:Faxdrawrect, withAttributes:  self.textAttributes(object: number  , fieldsRect: Faxdrawrect))
                }
                else
                {
                    number.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "fax_number")as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: Recipient_name
            if faxObject.recipient_name != nil
            {
                FaxtextSize = faxObject.recipient_name!.size(attributes: textFontAttributes)
                
                Faxdrawrect = CGRectFromString(fieldsDictionary.value(forKey: RECIPIENT_NAME)as! String)
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    faxObject.recipient_name?.draw(in:Faxdrawrect, withAttributes:  self.textAttributes(object: faxObject.recipient_name! , fieldsRect: Faxdrawrect))
                }
                else
                {
                    faxObject.recipient_name?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: RECIPIENT_NAME)as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: sender_name
            if faxObject.sender_name != nil
            {
                 FaxtextSize = faxObject.sender_name!.size(attributes: textFontAttributes)
                
                Faxdrawrect = CGRectFromString(fieldsDictionary.value(forKey: "sender_name")as! String)
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    faxObject.sender_name?.draw(in:Faxdrawrect, withAttributes:  self.textAttributes(object: faxObject.sender_name! , fieldsRect: Faxdrawrect))
                }
                else
                {
                    faxObject.sender_name?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "sender_name")as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: sender_phone
            if faxObject.sender_phone != nil
            {
                
                let number : String =  (faxObject.sender_phone)!
                 FaxtextSize  = number.size(attributes: textFontAttributes)
                Faxdrawrect = CGRectFromString(fieldsDictionary.value(forKey: "sender_phone")as! String)
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    faxObject.sender_phone?.draw(in:Faxdrawrect, withAttributes:  self.textAttributes(object: number  , fieldsRect: Faxdrawrect))
                }
                else
                {
                    faxObject.sender_phone?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "sender_phone")as! String), withAttributes: textFontAttributes)
                }
            }
            
            let dateformatter = DateFormatter()
            dateformatter.dateStyle = .medium
            let str   = dateformatter.string(from: NSDate() as Date)
            str.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "date")as! String), withAttributes: textFontAttributes)
            
            //MARK: subject
            if faxObject.subject != nil
            {
                FaxtextSize = faxObject.subject!.size(attributes: textFontAttributes)
                Faxdrawrect = CGRectFromString(fieldsDictionary.value(forKey: "subject")as! String)
                
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    faxObject.subject?.draw(in:Faxdrawrect, withAttributes: self.textAttributes(object: faxObject.subject!, fieldsRect: Faxdrawrect))
                }
                else
                {
                    faxObject.subject?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "subject")as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: Pages
            
            // Get the directory contents urls (including subfolders urls)
            intPageCount = Int(faxObject.page_count)
            
            String(format: "%d", intPageCount).draw(in:CGRectFromString(fieldsDictionary.value(forKey: "pages")as! String), withAttributes: textFontAttributes)
            
            //MARK:   sender_email
            if faxObject.sender_email != nil
            {
                FaxtextSize = faxObject.sender_email!.size(attributes: textFontAttributes)
                Faxdrawrect = CGRectFromString(fieldsDictionary.value(forKey: "sender_email")as! String)
                if(FaxtextSize.width>Faxdrawrect.size.width)
                {
                    faxObject.sender_email?.draw(in:Faxdrawrect, withAttributes: self.textAttributes(object: faxObject.sender_email!, fieldsRect: Faxdrawrect))
                }
                else
                {
                    faxObject.sender_email?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "sender_email")as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: note
            if  faxObject.note != nil
            {
                if let faxnotes = faxObject.note
                {
                    var faxnote : [String] = faxnotes.characters.split{$0 == ","}.map(String.init)
                    for i in 0..<faxnote.count
                    {
                        let note  = faxnote[i]

                        switch (note)
                        {
                        case "1" :
                            let imgChk : UIImage  =  UIImage(named: strChName)!
                            imgChk.draw(in: CGRectFromString(fieldsDictionary.value(forKey: "note_urgent")as! String))
                            break
                            
                        case "2" :
                            let imgChk : UIImage  =  UIImage(named: strChName)!
                            imgChk.draw(in: CGRectFromString(fieldsDictionary.value(forKey: "note_review")as! String))
                            break
                        case  "3" :
                            
                            
                            let imgChk : UIImage  =  UIImage(named: strChName)!
                            imgChk.draw(in: CGRectFromString( fieldsDictionary.value(forKey: "note_comment")as! String))
                            
                        case "4" :
                            
                            let imgChk : UIImage  =  UIImage(named: strChName)!
                            imgChk.draw(in: CGRectFromString(fieldsDictionary.value(forKey: "note_reply")as! String))
                            break
                        case "5" :
                            let imgChk : UIImage  =  UIImage(named: strChName)!
                            imgChk.draw(in: CGRectFromString(fieldsDictionary.value(forKey: "note_recycle")as! String))
                            break
                        default :
                            break
                        }
                    }
                }
            }
            
            //MARK: Coments
            if faxObject.comments != nil
            {
                var comentTextStyle : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                var commentAttributes = [NSFontAttributeName:textFont1 , NSParagraphStyleAttributeName :  comentTextStyle] as [String : Any]
                var commentTextSize : CGSize = faxObject.comments!.size(attributes: commentAttributes)
                let commentDrawRect : CGRect = CGRectFromString(fieldsDictionary.value(forKey:"comments")as! String)
                var commentFont1 = 16
                
                if(commentTextSize.width>commentDrawRect.size.width || commentTextSize.height >  commentDrawRect.size.height)
                {
                    if languageDirection == Locale.LanguageDirection.rightToLeft
                    {
                        comentTextStyle.alignment = NSTextAlignment.right
                    }
                    else
                    {
                        comentTextStyle.alignment = NSTextAlignment.left
                    }
                    
                    repeat{
                        if(commentTextSize.height>=commentDrawRect.size.height )
                        {
                            comentTextStyle  = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                            comentTextStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
                            commentFont1 -= 1
                            let font : UIFont = UIFont(name: "Helvetica", size: CGFloat(commentFont1))!
                            commentAttributes = [NSFontAttributeName : font, NSParagraphStyleAttributeName :  comentTextStyle]
                            commentAttributes = [NSFontAttributeName:font]
                            commentTextSize  = (faxObject.comments?.size(attributes: commentAttributes))!
                        }
                    }while (commentTextSize.height >  commentDrawRect.size.height)
                    faxObject.comments?.draw(in:commentDrawRect, withAttributes: commentAttributes)
                }
                    
                else
                {
                    faxObject.comments?.draw(in:CGRectFromString(fieldsDictionary.value(forKey: "comments")as! String), withAttributes: textFontAttributes)
                }
            }
            
            //MARK: Signature
            if FileManager().fileExists(atPath: (getPathURLOfContainer()?.appendingPathComponent(SIGNATURE_IMG1).path)!)
            {
                img_sign = UIImage(contentsOfFile: (getPathURLOfContainer()?.appendingPathComponent(SIGNATURE_IMG1).path)!)!
                signRect = nil
                
                signRect = CGRect (x:rect.size.width ,y:5,width: 134,height: 75.5)
                var const:CGFloat
                if faxObject.comments == ""{
                    const = -5.0
                }
                else
                {
                    const = 35
                }
                let signature_X =  rect.origin.x
                let signature_Y = (CGFloat(PDF_MEDIABOX_HEIGHT) - (rect.size.height + rect.origin.y)) - const
                
                if (templatesNO == 0)
                {
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect = CGRect (x: signature_X,y:rect.origin.y-myStringSize.height-signRect.size.height + 40 ,width: signRect.size.width,height :signRect.size.height)
                    }
                    else
                    {
                        signRect=CGRect (x: signature_X,   y:  signature_Y ,   width: signRect.size.width,  height:signRect.size.height)
                    }
                }
                else if (templatesNO == 1)
                {
                    
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect = CGRect(x: signature_X,y: rect.size.height - myStringSize.height + 60 ,width:  signRect.size.width,height : signRect.size.height)
                    }
                    else
                    {
                        signRect=CGRect (x: signature_X,   y:  signature_Y+15  ,   width: signRect.size.width,  height:signRect.size.height)
                    }
                    
                }
                else if (templatesNO == 2)
                {
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect = CGRect(x: signature_X, y: rect.origin.y-myStringSize.height-signRect.size.height + 50 ,width: signRect.size.width,height: signRect.size.height)
                    }
                    else
                    {
                        signRect=CGRect(x:signature_X,y:  signature_Y+15 ,width: 100,height: 75.5)
                    }
                }
                else if (templatesNO == 3)
                {
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect = CGRect(x:signature_X,y:  rect.origin.y-myStringSize.height + 80 , width: signRect.size.width,height:signRect.size.height)
                    }
                    else
                    {
                        signRect = CGRect(x : signature_X ,y: signature_Y+10 ,width:signRect.size.width  , height: signRect.size.height )
                    }
                }
                    
                else if (templatesNO == 4)
                {
                    
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect=CGRect(x: signature_X ,y: rect.size.height-myStringSize.height   ,width:  signRect.size.width,height: signRect.size.height)
                   }
                    else
                    {
                        signRect=CGRect(x: signature_X ,y:  signature_Y, width : signRect.size.width,height : signRect.size.height)
                    }
                }
                    
                else if (templatesNO == 5)
                {
                    if (rect.size.height > (signRect.size.height + myStringSize.height + 20))
                    {
                        signRect=CGRect(x: signature_X,y: rect.origin.y - myStringSize.height + 80 ,width :  signRect.size.width,height : signRect.size.height)
                    }
                    else
                    {
                        signRect = CGRect(x:signature_X,y:  signature_Y  ,width:  signRect.size.width,height : signRect.size.height)
                    }
                }
            }
            
            let fileExist = FileManager().fileExists(atPath: (getPathURLOfContainer()?.appendingPathComponent(LOGO_IMG).path)!)
            var logoRect: CGRect!
            
            //MARK: logo
            var img_copyright =  UIImage()
            if fileExist
            {
                img_copyright = UIImage(contentsOfFile: (getPathURLOfContainer()?.appendingPathComponent(LOGO_IMG).path)!)!
            }
            else
            {
                img_copyright = UIImage(named: "DefaultLogo")!
                //AddLogoViewController().resizeImage(image: UIImage(named:"ifax_logo")!, newWidth: 240)
            }
                
                if (templatesNO == 0)
                {
                    logoRect = CGRect(x : 240 , y: 18,width: 120, height:  70)
                }
                else if (templatesNO == 1)
                {
                    logoRect = CGRect(x: 240,y: 28 ,width: 120,height:  70)
                }
                else if (templatesNO == 2)
                {
                    logoRect = CGRect(x: 445 ,y: 110 ,width: 120,height:  70)
                }
                else if (templatesNO == 3)
                {
                    logoRect = CGRect(x: 240 ,y: 5,width:    120 ,height:  70)
                }
                else if (templatesNO == 4)
                {
                      logoRect = CGRect( x: 240 ,y: 5,width: 120 ,height: 70)
                }
                else if (templatesNO == 5)
                {
                    logoRect = CGRect(x: 240 ,y: 15,width:   120 ,height: 70)
                }

            context.translateBy(x: 0,y: CGFloat(PDF_MEDIABOX_HEIGHT))
            context.scaleBy(x: 1.0, y: -1.0)
            
            if (img_sign != nil){
                let  signatureImg : CGImage = img_sign.cgImage!
                pdfContext!.draw(signatureImg, in: signRect)
                signRect = nil
            }
            if fileExist || isAddLogo ==  true
            {
                pdfContext!.draw(img_copyright.cgImage!, in: logoRect)
            }
            
            pdfContext!.endPage ()
            UIGraphicsPopContext()
            pdfContext!.flush()
       
        }
    }
    
    func getLanguageDirection () -> Locale.LanguageDirection
    {
        var nameLangaue : String!
        for mode in UITextInputMode.activeInputModes
        {
            nameLangaue = mode.primaryLanguage
        }
        
        let language : Locale.LanguageDirection = Locale.characterDirection(forLanguage: nameLangaue)
        return language
    }
    
    
    //MARK: renderPage
    func renderPage(pageNum : NSInteger  ,currentRange : CFRange , framesetter  : CTFramesetter)-> CFRange
    {
        // Get the graphics context.
        let currentContext : CGContext = UIGraphicsGetCurrentContext()!
        currentContext.textMatrix = CGAffineTransform.identity
        
        let framePath : CGMutablePath = CGMutablePath()
        framePath.addRect(CGRect(x:72,y: 72, width:  468 , height:  648))
        
        let frameRef  : CTFrame = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)
        
        currentContext.translateBy(x: 0, y: 792)
        currentContext.scaleBy(x: 1.0, y: -1.0)
        CTFrameDraw(frameRef, currentContext)
        
        var currentRanges = currentRange
        currentRanges = CTFrameGetVisibleStringRange(frameRef)
        currentRanges.location += currentRange.length
        currentRanges.length = 0
        return currentRanges
    }

    //MARK: readRTFfile
    func readRTFfile(fileUrl : NSURL , fileExt : NSString)-> NSAttributedString
    {
        var strData :  NSAttributedString!
        if fileExt .isEqual(to: "rtf")
        {
            do
            {
                strData =  try NSAttributedString(fileURL: fileUrl as URL, options: [NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType], documentAttributes: nil)
                
            }
            catch{}
        }
        return strData
    }
    
    //MARK: create thumbnail From PDF.
    func thumbnailFromPDF(pdfFilePath : URL , thumbnailPath : URL, incomingThumbnail : Bool)
    {
        if FileManager.default.fileExists(atPath: pdfFilePath.path)
        {
        do
        {
            let aRect : CGRect = CGRect(x: 0, y : 5, width: 300, height: 400)  // thumbnail size
            if let pdf : CGPDFDocument = CGPDFDocument(pdfFilePath as CFURL)
            {
                var page : CGPDFPage!
                UIGraphicsBeginImageContext(aRect.size)
                
                let context : CGContext = UIGraphicsGetCurrentContext()!
                context.saveGState()
                context.translateBy(x: 0.0, y: aRect.height)
                context.scaleBy(x: 1.0, y: -1.0)
                context.setFillColor(gray: 1.0, alpha: 1.0)
                context.fill(aRect)
                
                // Grab the first PDF page
                page = pdf.page(at: 1)
                context.concatenate(page.getDrawingTransform(.cropBox, rect: aRect, rotate: 0, preserveAspectRatio: false))
                context.drawPDFPage(page)
                
                // Create the new UIImage from the context
                let  thumbnailImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                
                context.restoreGState()
                UIGraphicsEndImageContext()
                var dataPath : URL!
                if incomingThumbnail == true
                {
                    dataPath  = thumbnailPath.appendingPathComponent(String(format : "thumbnailTransmission.png"))//,TemplateNO))
                }
                else
                {
                    dataPath = thumbnailPath.appendingPathComponent(String(format : "thumbnail.png"))//,TemplateNO))
                }
                
                //        let str : String = String(dataPath)
                if FileManager.default.fileExists(atPath:dataPath.path)
                {
                    
                    // Remove Extra Edited Cover Pages
                    try FileManager.default.removeItem(at: dataPath)
                    
                }
                let imageData : Data = UIImagePNGRepresentation(thumbnailImage)!
                try imageData.write(to: dataPath)
            }
        }catch{
           
            }
        }
    }
    
   
    //MARK:  Make PDF from Splited PDF
    func CreateEditAttachmentPDF(OldpdfURL : URL , PageArray : NSMutableArray)
    {

        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let documentsDirectory  = documents.appendingPathComponent(OldpdfURL.lastPathComponent)
        pageRect = CGRect(x: 0, y: 0,width:  PDF_MEDIABOX_WIDTH,height:  PDF_MEDIABOX_HEIGHT)
        
        let fileUrl = NSURL(fileURLWithPath: documentsDirectory)
        
        let NewpdfContext = CGContext (fileUrl as CFURL , mediaBox: &pageRect, CFDictionaryCreateMutable(nil, 0, &keyCallbacks,&valueCallbacks))
        UIGraphicsPushContext(NewpdfContext!)
        
        
        // Old PDF
        
        let OldpdfURL : URL  =  NSURL.fileURL(withPath: OldpdfURL.path)
        let OldpdfRef : CGPDFDocument = CGPDFDocument(OldpdfURL as CFURL  )!
        var page : CGPDFPage!
        
        for j in 0..<PageArray.count
        {
            page = OldpdfRef.page(at: PageArray[j] as! Int)
            var mediaBox : CGRect = page.getBoxRect(.mediaBox)
            NewpdfContext?.beginPage (mediaBox: &mediaBox)
            NewpdfContext!.drawPDFPage(page)
            NewpdfContext!.endPage()
        }
        UIGraphicsPopContext()
    }

    
    //MARK: Recciepts for InComming Fax
    func getRecieptForReceived(Inbound:Inbound_messages) -> URL {
        let folderpath = getIncomingPath()?.appendingPathComponent("\(Inbound.folder_id)") as  URL?
        do
        {
            try FileManager.default.createDirectory(at: folderpath! as URL, withIntermediateDirectories: true, attributes: nil)
            
        } catch {}
        let pathForPDF =  getIncomingPath()?.appendingPathComponent("\(Inbound.folder_id)/transmission.pdf") as  URL!
        

        autoreleasepool{
            
            UIGraphicsBeginPDFContextToFile((pathForPDF?.path)!, CGRect.zero, nil)
            UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: 610, height: 800), nil)
            
            let imgsent = UIImageView(image: UIImage(named: "bg_receivedreceipt_small")!)
            imgsent.frame = CGRect(x: 0, y:0,width : 610,height : 800)
            imgsent.image!.draw(in: CGRect(x :0,y:   0,width : 610,height : 800))
            
            let textStyle1  : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle1.lineBreakMode =  NSLineBreakMode.byWordWrapping
            textStyle1.alignment = NSTextAlignment.left
            
            let textFont1 = UIFont.systemFont(ofSize: 17)
            let textAttributes = [  NSFontAttributeName: textFont1,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            
            let textFont2 = UIFont.boldSystemFont(ofSize: 17)
            let textAttributes1 = [  NSFontAttributeName: textFont2,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            
            let strCSID = "IFAX"
            
            
            
            let strStatus = "Received All Pages OK"
            var strMessageSize = ""
            
            if Inbound.message_size != nil
            {
                var inboundMessage = Inbound.message_size
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\t", with: "")
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\n", with: "")
                let fl = Double("\(inboundMessage!)")
                let size = fl!/1024 as Double
                strMessageSize = String(format: "\(Int64(round(size))) KB")
                //                "\(size) KB"
            }
            else{
                strMessageSize = "0 KB"
            }
            
            let strMessageID = String(describing: Inbound.transaction_id)
            
            if Inbound.receiver_fax_number != nil
            {
                Inbound.receiver_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes)
                let iFaxStr = IFAX_NUMBER
                iFaxStr.draw(in: CGRect(x: 55 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes1)
            }
            
            if Inbound.sender_fax_number != nil
            {
                let senderNumberStr = SENDER_NUMBER
                senderNumberStr.draw(in: CGRect(x: 55 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes1)
                let senderNumber = Inbound.sender_fax_number!
                if Int64(senderNumber) != nil {
                    Inbound.sender_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
                else
                {
                    Inbound.sender_fax_number!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
            }
            let csidStr = CSID_STR
            csidStr.draw(in: CGRect(x: 55 , y: 360-15, width :250,height : 25), withAttributes: textAttributes1)
            strCSID.draw(in: CGRect(x: 270 , y: 360-15, width :250,height : 25), withAttributes: textAttributes)
            
            let pagesStr = PAGES_STR
            pagesStr.draw(in: CGRect(x: 55 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes1)
            String(describing: Inbound.page_count).draw(in: CGRect(x: 270 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes)
            
            let statusStr = STATUS_STR
            statusStr.draw(in: CGRect(x: 55 , y: 426-15,width : 250,height: 25), withAttributes: textAttributes1)
            strStatus.draw(in: CGRect(x: 270 , y: 426-15,width : 250,height : 25), withAttributes: textAttributes)
            
            let messageSizeStr = MESSAGE_SIZE
            messageSizeStr.draw(in: CGRect(x: 55 , y: 461-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageSize.draw(in: CGRect(x: 270 , y: 461-15,width : 250, height: 25), withAttributes: textAttributes)
            
            if var strDuration = Inbound.mr_duration
            {
                let receiptDurationStr = RECEIPT_DURATION
                receiptDurationStr.draw(in: CGRect(x: 55 , y: 496-15,width : 250,height: 25), withAttributes: textAttributes1)
                let minute = floor(((strDuration as NSString).doubleValue)/60)
                let second = trunc(((strDuration as NSString).doubleValue) - minute * 60)
                
                if (Int(minute)  == 1)
                {
                    strDuration = String(format: "%d minute, %d seconds" ,Int(minute),Int(second))
                }
                else
                {
                    strDuration = String(format: "%d minutes, %d seconds" ,Int(minute),Int(second))
                }
                strDuration.draw(in: CGRect(x: 270 , y: 496-15,width : 250,height :25), withAttributes: textAttributes)
            }
            
            let messageIdStr = MESSAGE_ID
            messageIdStr.draw(in: CGRect(x: 55 , y: 530-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageID.draw(in: CGRect(x: 270 , y: 530-15,width : 250, height : 25), withAttributes: textAttributes)
            
            // Convert string to date object
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd HHmmSS VVVV"
            
            // Parse date and time object
            
            var currentDateStr: NSString = ""
            if let dateValue : NSDate = Inbound.date
            {
                if let timeValue : NSDate = Inbound.time
                {
                    let final = HomeViewController().convertDateAndTimeToString(date: dateValue as Date, time: timeValue as Date)
                    
                    let dateFormatter = DateFormatter()
                    
                    dateFormatter.dateFormat = "VVVV"
                    var localTimeZoneName: String { return TimeZone.current.identifier }
                    let regiouns = dateFormatter.string(from: final as Date)
                    currentDateStr = (regoinWiseDateFormate(date: final) + " " + regiouns) as NSString
//                  currentDateStr = dateFormatter.string(from: final as Date) as NSString
                }
            }
            
            let receiptTimeStr = RECEIPT_TIME
            receiptTimeStr.draw(in: CGRect(x: 55 , y: 564-15,width : 280,height: 25), withAttributes: textAttributes1)
            currentDateStr.draw(in: CGRect(x: 270 , y: 564-15, width : 300, height : 25), withAttributes: textAttributes)
            UIGraphicsEndPDFContext()
            
            let transmissionImage  = folderpath?.appendingPathComponent(String(format : "thumbnailTransmission.png"))
            if !FileManager().fileExists(atPath: (transmissionImage?.path)!)
            {
                self.thumbnailFromPDF(pdfFilePath : pathForPDF!, thumbnailPath : folderpath!, incomingThumbnail: true)
            }
        }
        return pathForPDF!
    }
    
    //MARK: Recciepts for OutGoing Fax

    func getRecieptForSent(outBound : Outbound_messages) -> URL
    {
        var ToPath: URL?
        
        ToPath =  getOutgoingPath()?.appendingPathComponent("\(outBound.folder_id)/transmission.pdf") as  URL?
        pageRect = CGRect(x: 0,y: 0,width : 600, height : 800)
        var url: CFURL
        url = (ToPath as! CFURL)
        
        let myDictionary : CFMutableDictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks,&valueCallbacks)
        
        guard let pdfContext = CGContext (url as CFURL, mediaBox: &pageRect, myDictionary)
        else
        {
            return URL(string:"")!
        }
        pdfContext.beginPage (mediaBox: &pageRect)
        UIGraphicsPushContext(pdfContext)
        
        let context = UIGraphicsGetCurrentContext()
        context!.translateBy(x: 0, y: 800)
        context!.scaleBy(x: 1.0, y: -1.0)
        
        let imgsent = UIImageView(image: UIImage(named: "bg_sentreceipt_small")!)
        imgsent.frame = CGRect(x: 0, y:0,width : 600,height : 800)
        imgsent.image!.draw(in: CGRect(x :0,y:   0,width : 600,height : 800))
        
//        let imglogo = UIImageView(image: UIImage(named: "ifax_transmission_log")!)
//        imglogo.image!.draw(in: CGRect(x :(imgsent.frame.size.width/2) - (imglogo.frame.size.width/2),y:   0,width : imglogo.frame.size.width,height : imglogo.frame.size.he))
        
        let textStyle1  : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        textStyle1.lineBreakMode =  NSLineBreakMode.byWordWrapping
        textStyle1.alignment = NSTextAlignment.left
       
        textFont1 = UIFont.systemFont(ofSize: 17)
        let textAttributes = [  NSFontAttributeName: textFont1,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
        
        textFont2 = UIFont.boldSystemFont(ofSize: 17)
        let textAttributes1 = [  NSFontAttributeName: textFont2,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
        
        var faxNumber:String?
        faxNumber = "+\(outBound.country_code) \(outBound.fax_number!)"
        let toStr = TO_STR
        toStr.draw(in: CGRect(x: 55 , y: 288-15,width: 250,height: 25), withAttributes: textAttributes1)
        if let strContact = faxNumber
        {
            strContact.draw(in: CGRect(x: 280 , y: 288-15,width: 250,height: 25), withAttributes: textAttributes)
        }
        
        let subjectStr = SUBJECT_LABEL
        subjectStr.draw(in: CGRect(x: 55 , y: 323-15,width: 250,height: 25), withAttributes: textAttributes1)
        if let strSubject = outBound.subject
        {
            strSubject.draw(in: CGRect(x: 280 , y: 323-15,width: 250,height: 25), withAttributes: textAttributes)
        }
        
        let statusStr = STATUS_STR
        statusStr.draw(in: CGRect(x: 55 , y: 358-15,width: 250,height: 25), withAttributes: textAttributes1)
        let strStatus = SENT_ALL_PAGE   //String(describing:outBound.fax_status)
        strStatus.draw(in: CGRect(x: 280 , y: 358-15,width: 250, height:25), withAttributes: textAttributes)
      
        let pagesSubmitted = PAGES_SUBMITTED_STR
        pagesSubmitted.draw(in: CGRect(x: 55 , y: 393-15,width: 250,height: 25), withAttributes: textAttributes1)
        let  strPageSent = String(describing:outBound.page_count)
        let  strPageSubmit = strPageSent
        strPageSubmit.draw(in: CGRect(x: 280 , y: 393-15,width: 250,height: 25), withAttributes: textAttributes)
        
        let pagesSent = PAGES_SENT_STR
        pagesSent.draw(in: CGRect(x: 55 , y: 427-15,width: 250,height: 25), withAttributes: textAttributes1)
        
        strPageSent.draw(in: CGRect(x: 280 , y: 427-15, width:250, height:25), withAttributes: textAttributes)
        
        var dateSubmit:String?
        
        dateSubmit = outBound.submit_time
        DLog(dateSubmit)
//        let final = HomeViewController().convertDateAndTimeToString(date: dateSubmit as Date, time: dateSubmit as Date)
//        DLog(final)
        let range = dateSubmit?.range(of: ":", options: String.CompareOptions.backwards, range: nil, locale: nil)

        dateSubmit?.remove(at: (range?.upperBound)!)
        dateSubmit?.remove(at: (range?.upperBound)!)
        dateSubmit?.remove(at: (range?.lowerBound)!)
        
        
        let submitTimeStr = SUBMIT_TIME_STR
        submitTimeStr.draw(in: CGRect(x: 55 , y: 461-15,width: 250,height: 25), withAttributes: textAttributes1)
        
        if let dateStrsubmit = dateSubmit
        {
            let FaxtextSize = outBound.completion_time!.size(attributes: textAttributes)
            let Faxdrawrect = CGRect(x: 280 , y: 461-15,width: 270,height: 25)
            
            if(FaxtextSize.width>Faxdrawrect.size.width)
            {
                dateStrsubmit.draw(in: CGRect(x: 280 , y: 461-15,width: 270,height: 25), withAttributes: self.textAttributes(object: dateStrsubmit , fieldsRect: Faxdrawrect))
            }
            else
            {
                dateStrsubmit.draw(in: CGRect(x: 280 , y: 461-15,width: 310, height:25), withAttributes: textAttributes)
            }
        }

        let completionTimeStr = COMPLETION_TIME_STR
        completionTimeStr.draw(in: CGRect(x: 55 , y: 495-15,width: 250,height: 25), withAttributes: textAttributes1)
        var dateComplete:String?
        dateComplete = outBound.completion_time
        let compRange = dateSubmit?.range(of: ":", options: String.CompareOptions.backwards, range: nil, locale: nil)
        dateComplete?.remove(at: (compRange?.upperBound)!)
        dateComplete?.remove(at: (compRange?.upperBound)!)
        dateComplete?.remove(at: (compRange?.lowerBound)!)
        
        
        if let dateStrCompletion = dateComplete
        {
            let FaxtextSize = outBound.completion_time!.size(attributes: textAttributes)
            let Faxdrawrect = CGRect(x: 280 , y: 495-15,width: 270,height: 25)
            if(FaxtextSize.width>Faxdrawrect.size.width)
            {
                dateStrCompletion.draw(in: CGRect(x: 280 , y: 495-15,width: 270,height: 25), withAttributes: self.textAttributes(object: dateStrCompletion , fieldsRect: Faxdrawrect))
            }
            else
            {
                dateStrCompletion.draw(in: CGRect(x: 280 , y: 495-15,width: 310,height: 25), withAttributes: textAttributes)
            }
        }
        
        let durationStr = DURATION
        durationStr.draw(in: CGRect(x: 55 , y: 529-15,width: 250,height: 25), withAttributes: textAttributes1)
        
        var  strDuration = String(describing:outBound.duration)
            //            strDuration = strDuration.int()
            let minute = floor(((strDuration as NSString).doubleValue)/60)
            let second = trunc(((strDuration as NSString).doubleValue) - minute * 60)
            
            if (Int(minute)  == 1)
            {
                strDuration = String(format: "%d minute, %d seconds" ,Int(minute),Int(second))
            }
            else
            {
                strDuration = String(format: "%d minutes, %d seconds" ,Int(minute),Int(second))
            }
          strDuration.draw(in: CGRect(x: 280 , y: 529-15, width:250, height:25), withAttributes: textAttributes)
        
        
        
        let transactionIdStr = TRANSACTION_ID
        transactionIdStr.draw(in: CGRect(x: 55 , y: 563-15,width: 250,height: 25), withAttributes: textAttributes1)
        let  transactionID = String(describing:outBound.transaction_id)
        transactionID.draw(in: CGRect(x: 280 , y: 563-15, width:250, height:25), withAttributes: textAttributes)
        
        pdfContext.endPage ()
       UIGraphicsPopContext()
         pdfContext.flush()
        
        
        return ToPath!;
    }
    
    func textAttributes(object : String , fieldsRect : CGRect) -> [String : Any]
    {
            textFont1  = UIFont(name: "Helvetica", size: 16)!
            var textStyle : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            var attributes = [NSFontAttributeName:textFont1 , NSParagraphStyleAttributeName :  textStyle] as [String : Any]
            var object_size : CGSize = object.size(attributes: attributes)
            var font1 = 16
            if(object_size.width>fieldsRect.size.width )
            {
                repeat{
                    if(object_size.width>=fieldsRect.size.width  ||  object_size.height >  fieldsRect.size.height)
                    {
                        font1 -= 1
                        textStyle  = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        textStyle.lineBreakMode = NSLineBreakMode.byClipping
                        let font : UIFont = UIFont(name: "Helvetica", size: CGFloat(font1))!
                        attributes = [NSFontAttributeName : font, NSParagraphStyleAttributeName :  textStyle]
                        attributes = [NSFontAttributeName:font]
                        object_size  =   object.size(attributes: attributes)
                        
                    }
                    else
                    {
                        let textStyle : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        textStyle.lineBreakMode = .byTruncatingTail
                        let font : UIFont = UIFont(name: "Helvetica", size: CGFloat(font1))!
                        attributes = [NSFontAttributeName:font, NSParagraphStyleAttributeName: textStyle]
                    }
                }while object_size.width >= fieldsRect.size.width
            }
        
        return attributes
    }

    func getRecieptForReceiveds(Inbound:Inbound_messages)
    {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let folderpath = getIncomingPath()?.appendingPathComponent("\(Inbound.folder_id)") as  URL?
            do
            {
                try FileManager.default.createDirectory(at: folderpath! as URL, withIntermediateDirectories: true, attributes: nil)
                
            } catch {}
            let pathForPDF =  getIncomingPath()?.appendingPathComponent("\(Inbound.folder_id)/transmission.pdf") as  URL!
            
            UIGraphicsBeginPDFContextToFile((pathForPDF?.path)!, CGRect.zero, nil)
            UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: 610, height: 800), nil)
            
            let imgsent = UIImageView(image: UIImage(named: "bg_receivedreceipt_small")!)
            imgsent.frame = CGRect(x: 0, y:0,width : 610,height : 800)
            imgsent.image!.draw(in: CGRect(x :0,y:   0,width : 610,height : 800))
            
            let textStyle1  : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle1.lineBreakMode =  NSLineBreakMode.byWordWrapping
            textStyle1.alignment = NSTextAlignment.left
            
            let textFont1 = UIFont.systemFont(ofSize: 17)
            let textAttributes = [  NSFontAttributeName: textFont1,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            
            let textFont2 = UIFont.boldSystemFont(ofSize: 17)
            let textAttributes1 = [  NSFontAttributeName: textFont2,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            let strCSID = "IFAX"
            let strStatus = "Received All Pages OK"
            var strMessageSize = ""
            
            if Inbound.message_size != nil
            {
                var inboundMessage = Inbound.message_size
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\t", with: "")
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\n", with: "")
                let fl = Double("\(inboundMessage!)")
                let size = fl!/1024 as Double
                strMessageSize = String(format: "\(Int64(round(size))) KB")
                //                "\(size) KB"
            }
            else{
                strMessageSize = "0 KB"
            }
            
            let strMessageID = String(describing: Inbound.transaction_id)
            
            if Inbound.receiver_fax_number != nil
            {
                Inbound.receiver_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes)
                let iFaxStr = IFAX_NUMBER
                iFaxStr.draw(in: CGRect(x: 55 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes1)
            }
            
            if Inbound.sender_fax_number != nil
            {
                let senderNumberStr = SENDER_NUMBER
                senderNumberStr.draw(in: CGRect(x: 55 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes1)
                let senderNumber = Inbound.sender_fax_number!
                if Int64(senderNumber) != nil {
                    Inbound.sender_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
                else
                {
                    Inbound.sender_fax_number!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
            }
            let csidStr = CSID_STR
            csidStr.draw(in: CGRect(x: 55 , y: 360-15, width :250,height : 25), withAttributes: textAttributes1)
            strCSID.draw(in: CGRect(x: 270 , y: 360-15, width :250,height : 25), withAttributes: textAttributes)
            
            let pagesStr = PAGES_STR
            pagesStr.draw(in: CGRect(x: 55 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes1)
            String(describing: Inbound.page_count).draw(in: CGRect(x: 270 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes)
            
            let statusStr = STATUS_STR
            statusStr.draw(in: CGRect(x: 55 , y: 426-15,width : 250,height: 25), withAttributes: textAttributes1)
            strStatus.draw(in: CGRect(x: 270 , y: 426-15,width : 250,height : 25), withAttributes: textAttributes)
            
            let messageSizeStr = MESSAGE_SIZE
            messageSizeStr.draw(in: CGRect(x: 55 , y: 461-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageSize.draw(in: CGRect(x: 270 , y: 461-15,width : 250, height: 25), withAttributes: textAttributes)
            
            if var strDuration = Inbound.mr_duration
            {
                let receiptDurationStr = RECEIPT_DURATION
                receiptDurationStr.draw(in: CGRect(x: 55 , y: 496-15,width : 250,height: 25), withAttributes: textAttributes1)
                let minute = floor(((strDuration as NSString).doubleValue)/60)
                let second = trunc(((strDuration as NSString).doubleValue) - minute * 60)
                
                if (Int(minute)  == 1)
                {
                    strDuration = String(format: "%d minute, %d seconds" ,Int(minute),Int(second))
                }
                else
                {
                    strDuration = String(format: "%d minutes, %d seconds" ,Int(minute),Int(second))
                }
                strDuration.draw(in: CGRect(x: 270 , y: 496-15,width : 250,height :25), withAttributes: textAttributes)
            }
            
            let messageIdStr = MESSAGE_ID
            messageIdStr.draw(in: CGRect(x: 55 , y: 530-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageID.draw(in: CGRect(x: 270 , y: 530-15,width : 250, height : 25), withAttributes: textAttributes)
            
            // Convert string to date object
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd HHmmSS VVVV"
            
            // Parse date and time object
            
            var currentDateStr: NSString = ""
            if let dateValue : NSDate = Inbound.date
            {
                if let timeValue : NSDate = Inbound.time
                {
                    let final = HomeViewController().convertDateAndTimeToString(date: dateValue as Date, time: timeValue as Date)
                    
                    let dateFormatter = DateFormatter()
                    
                    dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm VVVV"
                    dateFormatter.timeZone = NSTimeZone.local
                    currentDateStr = dateFormatter.string(from: final as Date) as NSString
                    
                }
            }
            
            let receiptTimeStr = RECEIPT_TIME
            receiptTimeStr.draw(in: CGRect(x: 55 , y: 564-15,width : 280,height: 25), withAttributes: textAttributes1)
            currentDateStr.draw(in: CGRect(x: 270 , y: 564-15, width : 300, height : 25), withAttributes: textAttributes)
            UIGraphicsEndPDFContext()
            let transmissionImage  = folderpath?.appendingPathComponent(String(format : "thumbnailTransmission.png"))
            if !FileManager().fileExists(atPath: (transmissionImage?.path)!)
            {
                self.thumbnailFromPDF(pdfFilePath : pathForPDF!, thumbnailPath : folderpath!, incomingThumbnail: true)
            }

        }
    }

  
    /*func createPdfWithFaxDataas(Inbound : Inbound_messages)
    {
        let folderpath = getIncomingPath()?.appendingPathComponent("\(Inbound.folder_id)") as  URL?
        do
        {
            try FileManager.default.createDirectory(at: folderpath! as URL, withIntermediateDirectories: true, attributes: nil)
            
        } catch {}

        let documentsDirectory  = folderpath?.appendingPathComponent(String(format : "transmission.pdf"))
//        let documentsDirectory  = getIncomingPath()?.appendingPathComponent("1").appendingPathComponent(String(format : "thumbnail.pdf"))
         var pageRect  = CGRect(x: 0, y:0,width:  595 ,height:  840)
        url  = documentsDirectory!
        let myDictionary : CFMutableDictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks,&valueCallbacks)
        let pdfContext = CGContext (url as CFURL, mediaBox: &pageRect, myDictionary)
        do{

            pdfContext?.beginPage (mediaBox: &pageRect)
            UIGraphicsPushContext(pdfContext!)
            let context : CGContext = UIGraphicsGetCurrentContext()!
            let pdfRef1 : CGPDFDocument = CGPDFDocument(NSURL.fileURL(withPath: Bundle.main.path(forResource: String(format: "%@", "bg_receivedreceipt_small"),  ofType: ".pdf")!) as CFURL)!
            
            guard let page = pdfRef1.page(at: 1)else
            {
                return
            }
            
            pdfContext!.drawPDFPage(page)
            context.translateBy(x: 0,y: CGFloat(PDF_MEDIABOX_HEIGHT))
            context.scaleBy(x: 1.0, y: -1.0)
            
            let textStyle1  : NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            textStyle1.lineBreakMode =  NSLineBreakMode.byWordWrapping
            textStyle1.alignment = NSTextAlignment.left
            
            let textFont1 = UIFont.systemFont(ofSize: 17)
            let textAttributes = [  NSFontAttributeName: textFont1,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            
            let textFont2 = UIFont.boldSystemFont(ofSize: 17)
            let textAttributes1 = [  NSFontAttributeName: textFont2,   NSParagraphStyleAttributeName: textStyle1] as [String : Any]
            
            let strCSID = "IFAX"
            let strStatus = "Received All Pages OK"
            var strMessageSize = ""
            
            if Inbound.message_size != nil
            {
                var inboundMessage = Inbound.message_size
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\t", with: "")
                inboundMessage = inboundMessage?.replacingOccurrences(of: "\n", with: "")
                let fl = Double("\(inboundMessage!)")
                let size = fl!/1024 as Double
                strMessageSize = String(format: "\(Int64(round(size))) KB")
            }
            else{
                strMessageSize = "0 KB"
            }
            
            let strMessageID = String(describing: Inbound.transaction_id)
            
            if Inbound.receiver_fax_number != nil
            {
                Inbound.receiver_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes)
                let iFaxStr = IFAX_NUMBER
                iFaxStr.draw(in: CGRect(x: 55 , y: 291-15,width : 250,height : 25), withAttributes:textAttributes1)
            }
            
            if Inbound.sender_fax_number != nil
            {
                let senderNumberStr = SENDER_NUMBER
                senderNumberStr.draw(in: CGRect(x: 55 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes1)
                let senderNumber = Inbound.sender_fax_number!
                if Int64(senderNumber) != nil {
                    Inbound.sender_fax_number!.formatFaxNumber!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
                else
                {
                    Inbound.sender_fax_number!.draw(in: CGRect(x: 270 , y: 326-15,width : 250,height : 25), withAttributes:textAttributes)
                }
            }
            let csidStr = CSID_STR
            csidStr.draw(in: CGRect(x: 55 , y: 360-15, width :250,height : 25), withAttributes: textAttributes1)
            strCSID.draw(in: CGRect(x: 270 , y: 360-15, width :250,height : 25), withAttributes: textAttributes)
            
            let pagesStr = PAGES_STR
            pagesStr.draw(in: CGRect(x: 55 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes1)
            String(describing: Inbound.page_count).draw(in: CGRect(x: 270 , y: 394-15,width : 250,height: 25), withAttributes: textAttributes)
            
            let statusStr = STATUS_STR
            statusStr.draw(in: CGRect(x: 55 , y: 426-15,width : 250,height: 25), withAttributes: textAttributes1)
            strStatus.draw(in: CGRect(x: 270 , y: 426-15,width : 250,height : 25), withAttributes: textAttributes)
            
            let messageSizeStr = MESSAGE_SIZE
            messageSizeStr.draw(in: CGRect(x: 55 , y: 461-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageSize.draw(in: CGRect(x: 270 , y: 461-15,width : 250, height: 25), withAttributes: textAttributes)
            
            if var strDuration = Inbound.mr_duration
            {
                let receiptDurationStr = RECEIPT_DURATION
                receiptDurationStr.draw(in: CGRect(x: 55 , y: 496-15,width : 250,height: 25), withAttributes: textAttributes1)
                let minute = floor(((strDuration as NSString).doubleValue)/60)
                let second = trunc(((strDuration as NSString).doubleValue) - minute * 60)
                
                if (Int(minute)  == 1)
                {
                    strDuration = String(format: "%d minute, %d seconds" ,Int(minute),Int(second))
                }
                else
                {
                    strDuration = String(format: "%d minutes, %d seconds" ,Int(minute),Int(second))
                }
                strDuration.draw(in: CGRect(x: 270 , y: 496-15,width : 250,height :25), withAttributes: textAttributes)
            }
            
            let messageIdStr = MESSAGE_ID
            messageIdStr.draw(in: CGRect(x: 55 , y: 530-15,width : 250,height: 25), withAttributes: textAttributes1)
            strMessageID.draw(in: CGRect(x: 270 , y: 530-15,width : 250, height : 25), withAttributes: textAttributes)
            
            // Convert string to date object
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd HHmmSS VVVV"
            
            // Parse date and time object
            
            var currentDateStr: NSString = ""
            if let dateValue : NSDate = Inbound.date
            {
                if let timeValue : NSDate = Inbound.time
                {
                    let final = HomeViewController().convertDateAndTimeToString(date: dateValue as Date, time: timeValue as Date)
                    
                    let dateFormatter = DateFormatter()
                    
                    dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm VVVV"
                    dateFormatter.timeZone = NSTimeZone.local
                    currentDateStr = dateFormatter.string(from: final as Date) as NSString
                    
                }
            }
            
            let receiptTimeStr = RECEIPT_TIME
            receiptTimeStr.draw(in: CGRect(x: 55 , y: 564-15,width : 280,height: 25), withAttributes: textAttributes1)
            currentDateStr.draw(in: CGRect(x: 270 , y: 564-15, width : 300, height : 25), withAttributes: textAttributes)
            
            pdfContext!.endPage ()
            UIGraphicsPopContext()
            pdfContext!.flush()
            
            let transmissionImage  = folderpath?.appendingPathComponent(String(format : "thumbnailTransmission.png"))
            
            if !FileManager().fileExists(atPath: (transmissionImage?.path)!)
            {
                self.thumbnailFromPDF(pdfFilePath : documentsDirectory!, thumbnailPath : (getIncomingPath()?.appendingPathComponent(String(format: "%d",Inbound.folder_id)))!,incomingThumbnail: true)
            }
        }
    }*/


}

                                                   
                                                   
                                                   
