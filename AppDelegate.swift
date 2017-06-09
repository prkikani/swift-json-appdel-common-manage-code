
//
//  AppDelegate.swift
//  iFax iOS
//
//  Created by MAC13 on 13/06/16.
//  Copyright © 2016 Moontechnolabs. All rights reserved.
//

import UIKit
import CoreData
import Fabric
import Crashlytics
import LocalAuthentication
import Contacts
import AddressBook
import SafariServices
import UserNotifications
import WatchConnectivity
import FBSDKCoreKit
import FBSDKLoginKit
import ZDCChat
import LinkedinSwift
import ZendeskSDK
import UXCam
import SwiftyStoreKit
import PhoneNumberKit
import KeychainSwift


// MARK: - Global variable
var CurentCoverPage : Int = 0
var selectedSubscriptionIndex = 0
let phoneNumberKit = PhoneNumberKit()
var stopJsonAsync = false
var contactFromPhone = NSMutableArray()
//var contactsFromPhone = [ContactEntry]()
var contactsFromPhone1 = [AnyObject]()
var overlayTransitioningDelegate = OverlayTransitioningDelegate()
//@available(iOS 9.0, *)

var insertPaymentInfo = NSMutableDictionary()
var contactArray : NSMutableArray = NSMutableArray()
var prepareInbFaxDict:[Any] = []
var SetupFee_PaymentDone = false
var SkipShowCreateORContinueSheet = false
var folder_key:Int64 = 0
var isForceLogin = false
var isForceLoginFromFreeCredits = false
var isForceLoginFromPromo = false
var isForceLoginFromSettingForPromo = false
var isForceLoginFromSettingForShare = false
var isPassPaymentInfo = false
var isCreditOpenFromSettings = false
var isCreditOpenFromWizards = false
var isDisplayRateAlert = false
var isShareOpenFromSettings = false
var trialMode = false
var sendFaxWithUseCreditOption = false
var isLowCredit = false
//var IsInGetListInbound = false
var autorenewProduct = ""
var countryCode = ""
var strSubPeriod = ""
var device_id = ""
var forceLoginFrom = 0
var GetIDFromSubinserAction = ""
var timeZoneName = ""
var device_token = ""
var myFaxNumber = ""
var externalFile:Bool = false
var externalFileURL : URL? = nil

//var NumberPurchaseAPI = ""
//var receiptStr = ""
var widgetFaxList : [Outbound_messages] = []
var currentController:UIViewController? = nil
var user_name = ""
var homeVC: HomeViewController? = nil
var dataTask:URLSessionDataTask? = nil
var outBoundCountryList = NSMutableArray()
var isCountryOpenFromCredit = false
var internetAlertCount:Int = 0
var transmissionReportPath : URL!
var isCurrentTransaction :Bool = false

let isAutoRenewProduct = true
var test =  NSMutableArray()
var ChekcingPriceInbOrObnd = -1
var urlarray  = NSMutableArray()

// MARK: - UIApplicationMain
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SFSafariViewControllerDelegate, UNUserNotificationCenterDelegate, URLSessionDelegate, URLSessionDataDelegate, WCSessionDelegate {
    var openfromother = false
    //MARK:- Apple Watch
    @available(iOS 9.0, *)
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void){
        if let unArchiveData = NSKeyedUnarchiver.unarchiveObject(with: messageData) as? NSDictionary
        {
            if unArchiveData.value(forKey: "mode") as! String == "fetch"
            {
                var inboundList : [Inbound_messages] = []
                let request: NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "time", ascending: false)]
                do {
                    inboundList = try self.managedObjectContext.fetch(request)
                    
                } catch {
//                    DLog("\(error)")
                }
                if inboundList.count>0
                {
                    let arrElements : NSMutableArray = NSMutableArray()
                    for dict in inboundList
                    {
                        let dicfaxList : NSMutableDictionary = NSMutableDictionary()
                        dicfaxList.setValue(dict.receiver_fax_number, forKey: "receiver_fax_number")
                        
                        let date = dict.date
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yy"
                        let dateString = dateFormatter.string(from: date! as Date)

                        dicfaxList.setValue(dateString, forKey: "date")
                        dicfaxList.setValue(dict.is_new, forKey: "is_new")
                        dicfaxList.setValue(dict.fax_api, forKey: "fax_api")
                        dicfaxList.setValue(String.init(format: "%d", dict.page_count), forKey: "page_count")
                        dicfaxList.setValue(String.init(format: "%d", dict.transaction_id), forKey: "transaction_id")
                        arrElements.add(dicfaxList)
                    }
                    
                    if arrElements.count > 0
                    {
                        let archiveData = NSKeyedArchiver.archivedData(withRootObject: arrElements)
                        replyHandler(archiveData)
                    }
                    else
                    {
                        let dict = ["status":"fail"]
                        let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                        replyHandler(archiveData)
                    }
                }
                else
                {
                    let dict = ["status":"fail"]
                    let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                    replyHandler(archiveData)
                }
            }
            else
            {
                var result : [Inbound_messages] = []
                
                // Initialize Fetch Request
                let fetchRequest : NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
                
                // Create Entity Request
                let entityDescription = NSEntityDescription.entity(forEntityName: "Inbound_messages", in: self.managedObjectContext)
                
                // Configure Fetch Request
                fetchRequest.entity = entityDescription
                
                // Predicate
                if let value = unArchiveData.value(forKey: "transaction_id") as? String
                {
                    if value != ""{
                        let predicate = "transaction_id=\(Int64(value)!)"
                        fetchRequest.predicate = NSPredicate(format: predicate)
                    }
                }
                do
                {
                    result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Inbound_messages]
                    if result.count>0
                    {
                        let update = result[0]
                        update.is_new = false
                        self.saveContext()
                        let dict = ["status":"success"]
                        let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                        replyHandler(archiveData)
                    }
                    else
                    {
                        let dict = ["status":"fail"]
                        let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                        replyHandler(archiveData)
                    }
                }
                catch
                {
                    let dict = ["status":"fail"]
                    let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                    replyHandler(archiveData)
                }
            }
        }
        else if let unArchiveData = NSKeyedUnarchiver.unarchiveObject(with: messageData) as? NSMutableDictionary
        {
            var result : [Inbound_messages] = []
            
            // Initialize Fetch Request
            let fetchRequest : NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
            
            // Create Entity Request
            let entityDescription = NSEntityDescription.entity(forEntityName: "Inbound_messages", in: self.managedObjectContext)
            
            // Configure Fetch Request
            fetchRequest.entity = entityDescription
            
            // Predicate
            if let value = unArchiveData.value(forKey: "transaction_id") as? String
            {
                if value != ""{
                    let predicate = "transaction_id=\(Int64(value)!)"
                    fetchRequest.predicate = NSPredicate(format: predicate)
                }
            }
            do
            {
                result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Inbound_messages]
                if result.count>0
                {
                    let update = result[0]
                    update.is_new = false
                    self.saveContext()
                    let dict = ["status":"success"]
                    let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                    replyHandler(archiveData)
                }
                else
                {
                    let dict = ["status":"fail"]
                    let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                    replyHandler(archiveData)
                }
            }
            catch
            {
                let dict = ["status":"fail"]
                let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
                replyHandler(archiveData)
            }
        }
        else
        {
            let dict = ["status":"fail"]
            let archiveData = NSKeyedArchiver.archivedData(withRootObject: dict)
            replyHandler(archiveData)
        }
    }
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
//        print("Wow")
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
//        print("Wow")
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//        print("Wow")
    }

    var window: UIWindow?
    var baseAlert : UIAlertController? = nil
    var OutboundCountryListArr = NSMutableArray()
    var creditCount = NSInteger()
    var lastViewController : UIViewController!
    var mutableData: NSMutableData =  NSMutableData()
    
    func loadAppdata(_ application: UIApplication,compltion:@escaping (()->()))
    {
        application.isIdleTimerDisabled = true
        // Initialise the variables
        countryCode = NSLocale.current.regionCode!
        CurrentDevice()
        // Fabric
        Fabric.with([Crashlytics()])
        Crashlytics().setUserIdentifier(device_id)
        
        // UXCam
        if IS_SANDBOX_OR_PRODUCTION_MODE == false //it is allways for Live Users not in developer mode.
        {
            UXCam.start(withKey: UXCAM_APP_ID)
        }
        
        // Firebase
        // Use Firebase library to configure APIs
        if FIRApp.defaultApp() == nil {
            FIRApp.configure()
        }
//        FIRApp.configure()
        ZDCChat.initialize(withAccountKey: ZENDESK_CHAT_KEY)
       
        ZDKRequests.configure({(account, _ requestCreationConfig) -> Void in
            requestCreationConfig?.tags = ["tag_one", "tag_two"]
            let txt: String = requestCreationConfig!.contentSeperator()
            let body = SettingsViewController().getAppAndUserDetails(forEmail: true)
            requestCreationConfig?.additionalRequestInfo = "\n\(body)"
            requestCreationConfig?.subject = "App Ticket"
        })
        
        ZDKRMA.configure({( account,config) -> Void in
            let versionString: String? = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String))"
            let appVersion: String = "App version: \(versionString)"
            config?.additionalRequestInfo = "Additional info here.\n\(appVersion)"
        })
        
        ZDKConfig.instance()
            .initialize(withAppId: "4af88f6f4545352f6b6368135eddadd7054146c9abb8402c",
                        zendeskUrl: "https://crowdedroad.zendesk.com",
                        clientId: "mobile_sdk_client_994c5e74ce535d1dcd66")
        
        let identity = ZDKAnonymousIdentity()
        identity.name = ""
        identity.email = ""
        identity.externalId = ""
        ZDKConfig.instance().userIdentity =  identity
   
        // Mirgration old database
        MigrateDataBase.sharedInstance.migrating()

//        DLog("line started : \(Date())")
        DLog(String(#line))
        UIApplication.shared.setStatusBarHidden(false, with: .slide)
        if #available(iOS 9.0, *){
            if WCSession.isSupported() {
                let session = WCSession.default()
                session.delegate = self
                session.activate()
            }
        }
        timeZoneName = TimeZone.ReferenceType.system.identifier
        
        DispatchQueue.global(qos: .default).async {
            settingDataFromsServer()
            //MARK:-  Framework, Library, SDK initialization
            // Dro   pbox
            let dropboxSession = DBSession(appKey: DROPBOXAPPKEY, appSecret: DROPBOXAPPSECRET, root: kDBRootDropbox)
            DBSession.setShared(dropboxSession)

            // Force update if user running old version
            forceUpadte(compltion:{ void in
                
            })
            self.defaultCover_Page()
        }

        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        let tracker = gai?.tracker(withTrackingId: kAnalyticsAccountId)
        gai?.trackUncaughtExceptions = true  // report uncaught exceptions
        gai?.dispatchInterval = TimeInterval(kGANDispatchPeriodSec);
        tracker?.allowIDFACollection = true;
        
        GAIDictionaryBuilder.createEvent(withCategory: GA_GENERAL, action: AppLoadAction, label: AppLoadLable, value: 1)
        tracker?.set(kGAIScreenName, value: "Home")
        let builder = GAIDictionaryBuilder.createScreenView()
        let userData = builder?.build() as NSDictionary? as? [AnyHashable: Any] ?? [:]
        tracker?.send(userData)
//        DLog("line 350 : \(Date())")
        
        // Commons configurations
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleCurrentViewController), name: NSNotification.Name(rawValue: "CurrentViewController"), object: nil)
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        //Push notification
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert,.badge, .sound]) { (granted, error) in
                if granted {
                    center.delegate = self
                    
                    // New fax
                    let action1 = UNNotificationAction(identifier: NEW_FAX_BTN, title: NEW_FAX_BTN, options: [.foreground])
                    // Resend
                    let action2 = UNNotificationAction(identifier: RESEND_BTN, title: RESEND_BTN, options: [.foreground])
                    
                    let category = UNNotificationCategory(identifier: "ACTIONABLE", actions: [action1, action2], intentIdentifiers: [], options: [])
                    UNUserNotificationCenter.current().setNotificationCategories([category])
                    
                } else {
//                    print("D'oh")
                }
            }
        }
        else {
            // Fallback on earlier versions
            
            // New fax
            let action1 = UIMutableUserNotificationAction()
            action1.activationMode = .foreground
            action1.title = NEW_FAX_BTN
            action1.identifier = NEW_FAX_BTN
            action1.isDestructive = false
            action1.isAuthenticationRequired = false
            
            // Resend
            let action2 = UIMutableUserNotificationAction()
            action2.activationMode = .foreground
            action2.title = RESEND_BTN
            action2.identifier = RESEND_BTN
            action2.isDestructive = false
            action2.isAuthenticationRequired = false
            
            let actionCategory = UIMutableUserNotificationCategory()
            actionCategory.identifier = "ACTIONABLE"
            actionCategory.setActions([action1, action2], for: .default)
            
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
            let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: [actionCategory])
            
            application.registerUserNotificationSettings(pushNotificationSettings)
        }
//        DLog("line middle : \(Date())")
       
        application.registerForRemoteNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        DispatchQueue.global(qos: .default).async {
            //        For BOX
            BOXContentClient.setClientID(BOX_SDK_CLIENT_ID, clientSecret: BOX_SDK_CLIENT_SECRET)
            compltion()
            checkStatusOfFaxes(faxStatus: [FAX_STATUS.SENDING.rawValue, FAX_STATUS.PAID_UNSENT.rawValue,FAX_STATUS.SENT.rawValue])
        }
        // Print the require data to help in debug
//        DLog("device_id...\(device_id)\n container_path...\(getPathURLOfContainer())")
        
        // Outbound country list
        var serverDataUpdate = DataModel.sharedInstance.syncDataStatusOf(syncName: SYNC_DATA.OUTBOUND_FAX.rawValue)
//         DLog("line End : \(Date())")
        if (UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) == nil)
        {
//             DLog("line End : \(Date())")
            serverDataUpdate = true
        }
        if serverDataUpdate
        {
//             DLog("line End : \(Date())")
            DLog(String(#line))
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                GetOutboundCountryList()
                GetinBoundCountryList()
            }
        }
        else
        {
//             DLog("line End : \(Date())")
            DLog(String(#line))
            let outboundList = getValueFromUserDefault(key: OUTBOUND_FAX_COUNTRY_LIST) as! NSMutableArray
            countryList = outboundList //Var used is modified in number purchase screen
            outBoundCountryList = outboundList //Var not modified.
        }

        timerFor1Min = Timer.scheduledTimer(timeInterval: (TimeInterval(30)), target: self, selector: #selector(AppDelegate.checkStaus), userInfo: nil, repeats: true);

//        DLog("line End : \(Date())")
        DLog(String(#line))
        
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        let keychain = KeychainSwift()
        if let deviceId = keychain.get(DEVICE_ID), deviceId != ""
        {
            DLog(device_id)
            device_id =  deviceId
        }
        else
        {
            device_id = (UIDevice.current.identifierForVendor?.uuidString)!
            device_id = device_id.replacingOccurrences(of: "-", with: "")
            
        }
        return true
    }
    
    func fetchInboundFaxes()
    {
        DispatchQueue.global(qos: .background).async {
           self.getFax()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
            application.isIdleTimerDisabled = true
            let array = DataModel.sharedInstance.getLastUnPaidUnsentFax()
                if array.count > 0
                {
                    setLocalNotificationForUnpaidDraft(outBoundMsg: array[0])
                }
        settingDataFromsServer()
        if ((timerFor1Min) != nil)
        {
            timerFor1Min.invalidate()
            timerFor1Min = nil;
        }
        timerFor5Min = Timer.scheduledTimer(timeInterval: (TimeInterval(45)), target: self, selector: #selector(AppDelegate.checkStaus), userInfo: nil, repeats: true)
        timerFor5Min.fire()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        let passCodeDefault = UserDefaults.standard.object(forKey: PASSCODE_ENABLE)
        if passCodeDefault != nil{
            let currentCode = Int(passCodeDefault as! String)!
            if UserDefaults.standard.object(forKey: PASSCODE_ENABLE) != nil && currentCode == 0
            {
                self.isPasscodeIsON()
            }
        }
        DispatchQueue.global(qos: .background).async
        {
            forceUpadte(compltion:{ void in
                
            })
        }
        // Refresh settings data
        settingDataFromsServer()
        if ((timerFor5Min) != nil)
        {
            timerFor5Min.invalidate()
            timerFor5Min = nil;
        }
        timerFor1Min = Timer.scheduledTimer(timeInterval: (TimeInterval(60)), target: self, selector: #selector(AppDelegate.checkStaus), userInfo: nil, repeats: true);
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        device_token = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        DLog("Device Token: \(device_token)")
        
        SendDeviceLog()
    }

    // Interactive push notification
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        if identifier == NEW_FAX_BTN
        {
            DispatchQueue.main.async {
                if selectedCountry.allKeys.count == 0
                {
                    if (UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) != nil)
                    {
                        let outboudArray = UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) as! NSMutableArray
                        if outboudArray.count > 0
                        {
                            let locale = NSLocale.current.regionCode
                            let filteredData2: NSArray = outboudArray.filtered(using: NSPredicate(format: "self.%@ contains[c] %@", "TerritoryCode", "\(locale!)")) as NSArray
                            selectedCountry = filteredData2[0] as! NSMutableDictionary
                        }
                        else
                        {
                            return
                        }
                    }
                    else
                    {
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    if UIApplication.topViewController() is WizardViewController{
                        UIApplication.topViewController()?.dismiss(animated: true, completion: {
                            let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                            self.window?.rootViewController?.present(vc, animated: true, completion: nil)
                        })
                    }
                    else
                    {
                        let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
                    }
                    
                }
            }
            
        }
        else if (identifier == RESEND_BTN)
        {
//            DLog("userInfo is: \(userInfo)")
            let t = userInfo["aps"] as! NSMutableDictionary
            
            let primaryKey = t["local_id"] as? String
//            DLog("t is: \(t) -- primary key : \(primaryKey)")
            if primaryKey != nil && (primaryKey?.characters.count)! > 0
            {
                if !networkAvailability(){
                    alertNetworkNotAvailableTryAgain(controller: UIApplication.topViewController()!)
                    return
                }
                
                let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(primaryKey!)!)
                if outboundMessages.count != 0
                {
                    let rCredit = outboundMessages[0].credits
                    let  credit = getValueFromUserDefault(key: DEFAULT_CREDIT_COUNT) as? Int64
                    print (rCredit)
                    if credit! < rCredit
                    {
                        wizardController?.resendFaxPayment(outboundEntity: outboundMessages[0])
                    }
                    else
                    {
//                        showLoadingAlert(RESENDING_TITLE, networkIndicator: true)
                        prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue,outboundEntity: outboundMessages[0])
                    }
                }
            }
        }
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // pull out the buried userInfo dictionary

//        DLog("response: \(response)")
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.actionIdentifier
        
        let draftKEY = userInfo["identifier"] as? String
        
        if identifier == NEW_FAX_BTN
        {
            DispatchQueue.main.async {
                if selectedCountry.allKeys.count == 0
                {
                    if (UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) != nil)
                    {
                        let outboudArray = UserDefaults.standard.value(forKey: OUTBOUND_FAX_COUNTRY_LIST) as! NSMutableArray
                        if outboudArray.count > 0
                        {
                            let locale = NSLocale.current.regionCode
                            let filteredData2: NSArray = outboudArray.filtered(using: NSPredicate(format: "self.%@ contains[c] %@", "TerritoryCode", "\(locale!)")) as NSArray
                            selectedCountry = filteredData2[0] as! NSMutableDictionary
                        }
                        else
                        {
                            return
                        }
                    }
                    else
                    {
                        return 
                    }
                }
                DispatchQueue.main.async {
                    if UIApplication.topViewController() is WizardViewController{
                        UIApplication.topViewController()?.dismiss(animated: true, completion: {
                            let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                            self.window?.rootViewController?.present(vc, animated: true, completion: nil)
                        })
                    }
                    else
                    {
                        let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                        self.window?.rootViewController?.present(vc, animated: true, completion: nil)
                    }

                }
            }
        }
        else if (identifier == RESEND_BTN)
        {
            let t = userInfo["aps"] as! NSDictionary
            DLog("t is: \(t)")
            let primaryKey = t["local_id"] as? String
            if primaryKey != nil && (primaryKey?.characters.count)! > 0
            {
                //    if([self internetAvaibility]==NO)
                if !networkAvailability(){
                    return
                }
                DispatchQueue.main.async {
                    let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(primaryKey!)!)
                    if outboundMessages.count != 0
                    {
                        prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue,outboundEntity: outboundMessages[0])
                    }
                }
            }
        }
        //From Draft Notification "Don't Forget to send fax you generate"
        else if (draftKEY == "DraftNotification"){
            if (identifier == LATER_BTN)
            {
                
            }
            else if (identifier == RATE_NO_THANKS)
            {
                UIApplication.shared.cancelAllLocalNotifications()
            }
            else
            {
                let folderID = userInfo["lastFaxFolderID"] as! Int
                let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(folderID)
                let ObjectsDict = NSMutableDictionary()
                if outboundMessages.count != 0
                {
                    ObjectsDict.setObject(outboundMessages[0], forKey: "draftEntity" as NSCopying)
                    ObjectsDict.setValue(DRAFTFAX, forKey: "action")
                    if UIApplication.topViewController() is WizardViewController{
                        UIApplication.topViewController()?.dismiss(animated: true, completion: {
                            let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                            vc.faxOutBoundObject =  ObjectsDict
                            UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
                        })
                    }
                    else
                    {
                        let vc = storyboard.instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
                        vc.faxOutBoundObject =  ObjectsDict
                        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
                    }
                }
            }
            removeValueFromUserDefault(key: DEFAULT_LAST_SCHEDULE_DRAFT, isSync: true)
        }
        // you must call the completion handler when you're done
        completionHandler()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        DLog("i am not available in simulator \(error)")
    }
    
//MARK: Get Callback from another Application URL
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let stringUrl = url.absoluteString
//        DLog("stringURL: \(String(stringUrl))")
        openfromother = true
        if #available(iOS 9.0, *) {
            let allowLaunch = launchAppFromAnotherAppWithURL(app, open: url as NSURL, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! NSString?, annotation: options[UIApplicationOpenURLOptionsKey.annotation] as Any)
            if allowLaunch
            {
                return true
            }
        }
        
        if stringUrl.contains("cancel"){
            NotificationCenter.default.post(name: NSNotification.Name("dropboxRegistrationCancel"), object: nil)
            return false
        }
        
        if stringUrl.contains("widgetResend")
        {
            URL_OUTER_APP_STRING = stringUrl
            let passCodeDefault = UserDefaults.standard.object(forKey: PASSCODE_ENABLE)
            if passCodeDefault != nil
            {
                let currentCode = Int(passCodeDefault as! String)!
                if UserDefaults.standard.object(forKey: PASSCODE_ENABLE) != nil && currentCode == 1
                {
                    resendFromWidget()
                }
            }
            else
            {
                resendFromWidget()
            }
//            if UserDefaults.standard.object(forKey: PASSCODE_ENABLE) == nil || UserDefaults.standard.object(forKey: PASSCODE_ENABLE) as! Int == 1
//            {
//                resendFromWidget()
//            }
        }
        else if stringUrl.contains("widgetLogin")
        {
            URL_OUTER_APP_STRING = stringUrl

            let passCodeDefault = UserDefaults.standard.object(forKey: PASSCODE_ENABLE)
            if passCodeDefault != nil
            {
                let currentCode = Int(passCodeDefault as! String)!
                if UserDefaults.standard.object(forKey: PASSCODE_ENABLE) != nil && currentCode == 1
                {
                    loginFromWidget()
                }
            }
            else
            {
               loginFromWidget()
            }
//            if UserDefaults.standard.object(forKey: PASSCODE_ENABLE) == nil || UserDefaults.standard.object(forKey: PASSCODE_ENABLE) as! Int == 1
//            {
//                loginFromWidget()
//            }
        }
            
        else if stringUrl.contains("home")
        {
            return true
        }
        
        // FB login Redirect To this App
        if #available(iOS 9.0, *) {
            
            if FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            {
                  return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            }
        }
        
        if #available(iOS 9.0, *) {
            if GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            {
                return GIDSignIn.sharedInstance().handle(url,
                                                         sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                         annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            }
        }
        
        if LinkedinSwiftHelper.shouldHandle(url as URL) {
            if #available(iOS 9.0, *) {
                return LinkedinSwiftHelper.application(app, open: url as URL, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                       annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            } else {
                // Fallback on earlier versions
            }
        }
        
        if (!stringUrl.contains("file://"))
        {
            if DBSession.shared().handleOpen(url) {
                if DBSession.shared().isLinked() {
                    NotificationCenter.default.post(name: NSNotification.Name("didLinkToDropboxAccountNotification"), object: nil)
                    return true
                }
            }
        }
        return false
    }

    func application(application: UIApplication,
                     openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if GIDSignIn.sharedInstance().handle(url as URL!,sourceApplication: sourceApplication,annotation: annotation)
        {
            return GIDSignIn.sharedInstance().handle(url as URL!,sourceApplication: sourceApplication,annotation: annotation)
        }
            // FB login Redirect To this App
        else if FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication, annotation: annotation)
        {
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication, annotation: annotation)
        }
     else
        {
            return LinkedinSwiftHelper.application(application, open: url as URL, sourceApplication: sourceApplication,
                                                   annotation: annotation)
        }
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        openfromother = true
//         return GIDSignIn.sharedInstance().handle(url as URL!,sourceApplication: sourceApplication,annotation: annotation)
      
        if #available(iOS 9.0, *) {
            let allowLaunch = launchAppFromAnotherAppWithURL(application, open: url as NSURL, sourceApplication: UIApplicationOpenURLOptionsKey.sourceApplication as NSString?, annotation: UIApplicationOpenURLOptionsKey.annotation)
            return allowLaunch
        } else {
            return true
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        let allowLaunch = launchAppFromAnotherAppWithURL(application, open: url as NSURL, sourceApplication: sourceApplication as NSString?, annotation: annotation)
        openfromother = true
        return allowLaunch
    }
    
    func launchAppFromAnotherAppWithURL(_ application: UIApplication, open url: NSURL, sourceApplication: NSString?, annotation : Any) -> Bool
    {
        let stringUrl = url.absoluteString
        if (stringUrl?.contains("file://"))!
        {
            var isFromUIDocumentIntraction : Bool = false
            
            if NSString(string:url.absoluteString!).range(of: FILEBASE_CODE).location == NSNotFound
            {
                isFromUIDocumentIntraction = true
                hideLoadingAlert()
            }
            else
            {
                isFromUIDocumentIntraction = false
                hideLoadingAlert()
            }
            //        var finalPath: URL? = nil
            if !isFromUIDocumentIntraction {
                do {
                    let ReceivedFileName = url.absoluteString?.replacingOccurrences(of: FILEBASE_CODE_PATH, with: "")
                    let path: URL? = getPathURLOfContainer()?.appendingPathComponent(ReceivedFileName!)
                    let data1 = try Data(contentsOf: path!)
                    try data1.write(to: path!)
                }catch {}
            }
            if isFromUIDocumentIntraction
            {
                self.loadExternalFilewithUrlString(url: url as URL)
            }
            return false
        }
        
        // Dropbox
        if (stringUrl?.contains("cancel"))!
        {
            NotificationCenter.default.post(name: NSNotification.Name("dropboxRegistrationCancel"), object: nil)
            return false
        }
        if DBSession.shared().handleOpen(URL(string: stringUrl!)) {
            if DBSession.shared().isLinked() {
                NotificationCenter.default.post(name: NSNotification.Name("didLinkToDropboxAccountNotification"), object: nil)
                return true
            }
        }
        // FB login Redirect To this App
        if FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication as String!, annotation: annotation)
        {
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication as String!, annotation: annotation)
        }
        
        // Linkedin sdk handle redirect
        if LinkedinSwiftHelper.shouldHandle(url as URL) {
            return LinkedinSwiftHelper.application(application, open: url as URL, sourceApplication: sourceApplication as String?, annotation: annotation)
        }
        
        // Google login
        let googleLogin: Bool = GIDSignIn.sharedInstance().handle(url as URL!,sourceApplication: sourceApplication as String!,annotation: annotation)
        if googleLogin
        {
            return true
        }
        
       return false
        
    }
    
    func loadExternalFilewithUrlString(url : URL)
    {
        externalFile  = false
        externalFileURL = url
        if (externalFileURL != nil)
        {
            do {
                var component = [Any]()
                component = (externalFileURL?.absoluteString.components(separatedBy: "/"))!
                var frompathFile: String = component.last as! String
                frompathFile = frompathFile.replacingOccurrences(of: "%20", with: " ")
                frompathFile = frompathFile.replacingOccurrences(of: "%2520", with: " ")
//                DLog("\(frompathFile)")
                let filePath: URL = getPathURLOfContainer()!.appendingPathComponent("mail-\(frompathFile)")
                if frompathFile.lowercased().hasSuffix(".png") || frompathFile.lowercased().hasSuffix(".jpg") || frompathFile.lowercased().hasSuffix(".jpeg") || frompathFile.lowercased().hasSuffix(".bfp") || frompathFile.lowercased().hasSuffix(".tiff")
                {
                    let image = try UIImage(data: Data(contentsOf: externalFileURL!))
                    try UIImageJPEGRepresentation(image!, 1.0)?.write(to: filePath)
                    
                }
                else if frompathFile.lowercased().hasSuffix(".pdf")
                {
                        do {
                            try FileManager.default.moveItem(at: externalFileURL!, to: filePath)
                        }
                        catch {
                        }
                        //                            self.fileAttachedFromAnotherApp()
//                        let url: CFURL? = filePath as CFURL
//                        var document: CGPDFDocument? = nil
//                        document = CGPDFDocument(url!)!
                }
                else{
                    do {
                        try FileManager.default.moveItem(at: externalFileURL!, to: filePath)
                    }
                    catch {
                    }
                }
                DLog(externalFileURL)
                let documentsURL = try! FileManager().url(for: .documentDirectory,
                                                          in: .userDomainMask,
                                                          appropriateFor: nil,
                                                          create: true)
                var DocumentUrlArray = externalFileURL?.path.components(separatedBy: "/")
                DLog((DocumentUrlArray?.last)!)
                let fooURL = documentsURL.appendingPathComponent((DocumentUrlArray?.last)!)
                DLog(fooURL)
                    let fileExists =  FileManager().fileExists(atPath: fooURL.path)
                    
                    if fileExists
                    {
                            do
                            {
                                 try FileManager.default.removeItem(at:fooURL)
                            }
                            catch
                            {
                                
                            }
                        
                
                    }
        
                if try externalFileURL!.checkResourceIsReachable()
                {
                    try FileManager.default.removeItem(at: externalFileURL!)
                }
            } catch {}
//            if let values = UIApplication.topViewController()
//            {
//                if values is WizardViewController {
//                    let wizard = UIApplication.topViewController() as! WizardViewController
//                    wizard.backDismiss(compltion:
//                        { _ in
//                            
//                    })
//                }
//            }
          
            _ = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WizardViewController") as! WizardViewController
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController
            {
                if rootViewController is UITabBarController
                {
                    (rootViewController as! UITabBarController).selectedIndex = 0
                    
                    if let values = UIApplication.topViewController()
                    {
                        if values is HomeViewController {
                            DispatchQueue.main.async
                                {
                                    (values as! HomeViewController).FromEmails()
                                }
                        }
                        else
                        {
                            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: { _ in
                                
                                 if let values = UIApplication.topViewController()
                                 {
                                    if values is HomeViewController {
                                    DispatchQueue.main.async {
                                            (values as! HomeViewController).FromEmails()
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        if let value = UIApplication.topViewController()
        {
            if value is UIAlertController
            {
                value.dismiss(animated: true, completion:{ UIApplication.topViewController()!.dismiss(animated: true, completion: {
                    if UIApplication.shared.keyWindow?.rootViewController as? UITabBarController != nil
                    {
                        let tababarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
                        tababarController?.selectedIndex = 0
                        UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
                    }
                })})
                
            }
            else if value is ShareSheetViewController
            {
                value.dismiss(animated: true, completion:{ UIApplication.topViewController()!.dismiss(animated: true, completion: {
                    if UIApplication.shared.keyWindow?.rootViewController as? UITabBarController != nil
                    {
                        let tababarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
                        tababarController?.selectedIndex = 0
                    }
                })})
                
            }
            
        }
        hideLoadingAlertWithComplition {
            if UIApplication.shared.keyWindow?.rootViewController as? UITabBarController != nil
            {
                let tababarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
                tababarController?.selectedIndex = 0
            }
            else
            {
                UIApplication.topViewController()!.navigationController?.popToRootViewController(animated: false)
            }
        }
        let t = userInfo["aps"] as! NSMutableDictionary
     
        
        if t.value(forKey: "renewNumber") != nil
        {
            if t["renewNumber"] as! String == "ByPaypal"
            {
                if #available(iOS 9.0, *) {
                    let SV = SFSafariViewController(url: URL(string: t["url"] as! String)!)
                    SV.delegate = self
                    self.window?.rootViewController?.present(SV, animated: true, completion: nil)
                    
                } else {
                    // Fallback on earlier versions
                    if UIApplication.shared.canOpenURL(URL(string: t["url"] as! String)!)
                    {
                        UIApplication.shared.openURL(URL(string: t["url"] as! String)!)
                    }
                }
            }
        }
        else if t.value(forKey: "feedback_url") != nil
        {
            if #available(iOS 9.0, *) {
                let SV = SFSafariViewController(url: URL(string: t["feedback_url"] as! String)!)
                SV.delegate = self
                self.window?.rootViewController?.present(SV, animated: true, completion: nil)
                
            } else {
                if UIApplication.shared.canOpenURL(URL(string: t["feedback_url"] as! String)!)
                {
                    UIApplication.shared.openURL(URL(string: t["feedback_url"] as! String)!)
                }
            }
        }
     
        else if t.value(forKey: "zendesk") != nil{
            if t["zendesk"] as! String == "1"
            {
                self.perform(#selector(AppDelegate.openSupportVC), with: nil, afterDelay: 10.0)
            }
        }
        else if t.value(forKey: "failed_reason") != nil{
            let primaryKey = t["local_id"] as? String
            let pKey = Int(primaryKey!)
            if pKey != nil
            {
                let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(primaryKey!)!)
                if outboundMessages.count > 0{
                    let outboundEntity = outboundMessages[0]
                    outboundEntity.message = t["failed_reason"] as? String
                    displayFaxFailedAlert(outboundRecord: outboundEntity ,message:t["message"] as! String)
                }
                DispatchQueue.global(qos: .background).async {
                    checkStatusOfFaxes(faxStatus: [FAX_STATUS.SENDING.rawValue, FAX_STATUS.SENT.rawValue])
                }
            }
        }
        else
        {
            if t.value(forKey: "notify") != nil
            {
                    DispatchQueue.global(qos: .background).async {
                        checkStatusOfFaxes(faxStatus: [FAX_STATUS.SENDING.rawValue, FAX_STATUS.SENT.rawValue])
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        CurrentDevice()        
//        DLog("topViewControllerWithRootViewController: \(UIApplication.topViewController()))")
        if UIApplication.topViewController() is SignatureViewController {
            
            let secondController = UIApplication.topViewController() as! SignatureViewController
            if secondController.isPresented { // Check current controller state
                return [.landscapeLeft, .portrait, .landscapeRight]
            } else {
                
                if isThisForiPad == true
                {
                    return [.portrait, .landscapeLeft, .landscapeRight]
                }
                else
                {
                    return UIInterfaceOrientationMask.portrait;
                }
            }
        }
        else
        {
            if isThisForiPad == true
            {
                return [.portrait, .landscapeLeft, .landscapeRight]
            }
            else
            {
                return UIInterfaceOrientationMask.portrait;
            }
        }
    }
    
    func openSupportVC()
    {
        if let value = UIApplication.topViewController()
        {
            if isThisForiPad == true
            {
                if value.presentedViewController?.modalPresentationStyle == UIModalPresentationStyle.popover
                {
                    value.dismiss(animated: true, completion: nil)
                }
                else if value is UIDocumentPickerViewController
                {
                    value.dismiss(animated: true, completion: nil)
                }
                else if value is UIImagePickerController
                {
                    value.dismiss(animated: true, completion: nil)
                }
            }
            if value is UIAlertController
            {
                value.dismiss(animated: true, completion: nil)
            }
            
        }
        SettingsViewController().openIfaxSupport()
    }
    
    func topViewControllerWithRootViewController(_ rootViewController: UIViewController!) -> UIViewController? {
        if (rootViewController == nil) { return nil }
        
        if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController.presentedViewController)
            
        }
        return rootViewController
    }
    
    
    func GetListInboundFaxNumber(_ faxNumber:String, userName:String){

        if !networkAvailability(){
             DispatchQueue.main.async {
            alertNetworkNotAvailableTryAgain(controller: UIApplication.topViewController()!)
            }
            return
        }
        
        // Remains: passing dynamic parameter
            let dict = NSMutableDictionary()
            let bundle_id = BUNDLE_VERSION as? String
            var params = ""
        
        var parent_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if parent_id == nil
        {
            parent_id = ""
        }
         var faxAPI = ""
            if  faxnumbers.count  > 0
            {
                for i in 0..<faxnumbers.count
                {
                    let faxNumberDetails = faxnumbers[i]
                    if faxNumberDetails["faxNumber"] as! String == faxNumber
                    {
                        faxAPI = faxNumberDetails["FAXAPI"] as! String
                    }
                }
            }
        var message_id = ""
        message_id  =  String(DataModel.sharedInstance.getMaxTransctionIdFromInboundFax(faxNumber))
        
            if faxAPI == "1"
            {
                params = String(format:"%@?userName=%@&bundleId=%@&faxNumber=%@&messageId=%@&parentId=%@&messageId_V=0&device_id=%@&os=\(OS_NAME)",GET_MESSAGES,userName,bundle_id!,faxNumber,message_id,parent_id!,device_id)
            }
            else
            {
                params = String(format:"%@?userName=%@&bundleId=%@&faxNumber=%@&messageId=0&messageId_V=%@&parentId=%@&device_id=%@&os=\(OS_NAME)",GET_MESSAGES,userName,bundle_id!,faxNumber,message_id,parent_id!,device_id)
            }
            
//            DLog("\(params)")
            dict.setValue(params, forKey: "url")
            dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        if stopJsonAsync == false
        {
            self.sendAsynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8), completion: { (data) in
                if data != nil
                {
                    let reader : XMLReader = XMLReader()
                    reader.rootName = "messageDetails"
                    let responseArray:[Any] = reader.parseXMLWithData(data! as Data) as [Any]
                    //                DLog("Response-->\(responseArray)")
                    
                    var faxRecords:[Any] = []
                    var inboudFaloderId = 0
                    inboudFaloderId = Int(DataModel.sharedInstance.getMaxFolderInBoundEntity())
                    var folderId = inboudFaloderId
                    var inboundList : [Inbound_messages] = []
                    inboundList = DataModel.sharedInstance.getInBoundMessages()
                    if  responseArray.count > 0
                    {
                        DispatchQueue.main.async {
                            homeVC?.enabeDisableBarButton(bool: false)
                            //                        startSpinner(type: 16, message: "", networkIndicator: true, color: .black)
                        }
                        test.removeAllObjects()
                        for index in 0 ..< responseArray.count
                        {
                            let x = index
                            var recordData:[String:Any] = [:]
                            recordData = responseArray[index] as! Dictionary<String, Any>
                            var dataDictionary:[String:Any] = [:]
                            var foundDuplicate: Bool
                            
                            foundDuplicate = false
                            //static
                            dataDictionary["status"] = "99"
                            dataDictionary["sentTo"] = faxNumber
                            dataDictionary["isNew"] = "1" // not clear need to discuss
                            dataDictionary["primaryKey"] = String(folderId)
                            test.add(x)
                            //faxNo
                            
                            if let value = recordData["sender"] as? String {
                                if value != ""{
                                    dataDictionary["faxNo"] = value
                                }
                                else{
                                    dataDictionary["faxNo"] = "Unknown"
                                }
                            }
                            else{
                                dataDictionary["faxNo"] = "Unknown"
                            }
                            
                            //FaxSendAPI
                            //if let value =  responseArray.object(at:index)["FaxAPI"] as? String{
                            if let value =  recordData["FaxAPI"] as? String{
                                if value == "1"{
                                    dataDictionary["FaxSendAPI"] = "INTERFAX"
                                }
                                else{
                                    dataDictionary["FaxSendAPI"] = "VITELITY"
                                }
                            }
                            else{
                                dataDictionary["FaxSendAPI"] = "VITELITY"
                            }
                            
                            // ServerId
                            //if let value =  responseArray.object(at:index)["id"] as? String {
                            if let value =  recordData["id"] as? String {
                                if value != ""{
                                    dataDictionary["ServerId"] = value
                                }
                            }
                            
                            // docId
                            //if let value =  responseArray.object(at:index)["messageId"] as? String {
                            if let value =  recordData["messageId"] as? String {
                                if value != ""{
                                    dataDictionary["docId"] = value
                                }
                            }
                            
                            // pageNumber
                            //if let value =  responseArray.object(at:index)["pages"] as? String {
                            if let value =  recordData["pages"] as? String {
                                if value != ""{
                                    dataDictionary["pageCount"] = value
                                }
                            }
                            
                            // pageNumber
                            //if let value =  responseArray.object(at:index)["pages"] as? String {
                            if let value =  recordData["MRDuration"] as? String {
                                if value != ""{
                                    dataDictionary["MRDuration"] = value
                                }
                            }
                            // pageNumber
                            //if let value =  responseArray.object(at:index)["pages"] as? String {
                            if let value =  recordData["messageSize"] as? String {
                                if value != ""{
                                    dataDictionary["messageSize"] = value
                                }
                            }
                            
                            //Date and time
                            //if let resposnseDate = responseArray.object(at:index)["recieveTime"] as? String
                            if let resposnseDate = recordData["recieveTime"] as? String
                            {
                                // Seprate recieveTime
                                let doNotWant = CharacterSet.init(charactersIn: "-T:")
                                let seprateArray : [String] = resposnseDate.components(separatedBy: doNotWant)
                                let replceDateStr = seprateArray.joined()
                                
                                // Convert string to date object
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyyMMddHHmmSS"
                                let resposnseDate : Date = dateFormatter.date(from: replceDateStr)!
                                
                                // Parse date and time object
                                dateFormatter.dateFormat = "MM-dd-yyyy"
                                let currentDateStr = dateFormatter.string(from: resposnseDate)
                                dateFormatter.dateFormat = "HH:mm:ss"
                                let currentTimeStr = dateFormatter.string(from: resposnseDate)
                                
                                dataDictionary["sentDate"] = currentDateStr
                                dataDictionary["times"] = currentTimeStr
                            }
                            
                            for i in 0 ..< inboundList.count
                            {
                                let msg = inboundList[i]
                                let transactinon = String(msg.transaction_id)
                                setValueInUserDefault(key: DEFAULT_INCOMMING_COLLECTION_RELOAD, value: "true",isSync: true)
                                if transactinon == dataDictionary["docId"] as! String{
                                    foundDuplicate = true
                                    test.add(i)
                                    break
                                }
                            }
                            folderId = folderId + 1
                            if !foundDuplicate
                            {
                                faxRecords.append(dataDictionary)
                            }
                        }
                        
                        homeVC?.fetchInccomingFaxDidCompleted()
                        MigrateDataBase.sharedInstance.faxDetailDataMigratingOnCoreDatabase(records: faxRecords)
                        DLog("Totale incomming messages fetch : \(faxRecords.count)")
                    }
                }
                else
                {
                    DLog("Get incomming messages fail")
                }
            })
        }
        // Call : Fetch Incomming fax completed notification
    }
    
       // MARK: - webservice Synch and  Asynch methods
    func sendAsynchronousRequestWithParameters(_ dict : NSMutableDictionary, andPostData postData: Data?, completion: @escaping (_ data: NSData?) -> Void)
    {
        // Make and set request data
        if stopJsonAsync == false
        {
            let url : NSURL = NSURL(string: dict["url"] as! String)!
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            if let val = dict["request_time_out"] {
                request.timeoutInterval = val as! TimeInterval
            } else {
                request.timeoutInterval = TimeInterval(REQUEST_TIMEOUT_INTERVAL)
            }
            
            if url.lastPathComponent?.lowercased() == SEND_FAX_URL
            {
                request.timeoutInterval = 1800
            }
            
            if (dict["req_method"] as? String != nil){
                request.httpMethod = (dict["req_method"] as! String)
            }
            if (postData != nil)
            {
                request.httpBody = postData
            }
            request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
            
            // Create task
            let session: URLSession = URLSession.shared
            dataTask  = session.dataTask(with: request as URLRequest, completionHandler:  { data, response, error in
                
                if (error != nil || data == nil)
                {
                    var msg = error!.localizedDescription
                    if msg == ""
                    {
                        msg = RQST_TIMES_OUT_MSG
                    }
                    DLog("\(RQST_TIMES_OUT_MSG)")
                    // use UIAlertView
                    DispatchQueue.main.async {
                          ForceSTopIndicator()
                    }
                }
                completion(data as NSData?)
            })
            dataTask?.resume()
        }
        else
        {
            dataTask?.cancel()
            completion(nil)
        }
    }
    
    func sendSynchronousRequestWithParameters(_ dict : NSMutableDictionary, andPostData postData : NSData?) -> NSData?
    {
        dataTask?.cancel()
        var callCount: Int = 0
        var responseData: NSData? = nil
        stopJsonAsync = true
        var api_recall : Int!
          DLog("call the API => \(String(describing: dict["url"]))")
        repeat{
            callCount += 1
            responseData = nil
            // Make and set request data
            
            let url = dict["url"] as! String?
            guard let endpoint = URL(string: url!) else {
                DLog("Error creating endpoint")
                return nil
            }
            var request = URLRequest(url: endpoint)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//            var request = URLRequest(url: endpoint)
            
            if let val = dict["request_time_out"] {
                request.timeoutInterval = val as! TimeInterval
            } else
            {
                if dict["url"] as! String == RECEIVE_FAX_FILE
                {
                   request.timeoutInterval = TimeInterval(REQUEST_TIMEOUT_INTERVAL_2MINITE)
                }
                else
                {
                    request.timeoutInterval = TimeInterval(REQUEST_TIMEOUT_INTERVAL)
                }
            }
            
            if (dict["req_method"] as? String != nil){
                request.httpMethod = (dict["req_method"] as! String)
            }
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if (postData != nil)
            {
                request.httpBody = postData as? Data
            }
            
            let semaphore : DispatchSemaphore = DispatchSemaphore(value: 0)
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil || data == nil{
//                    DLog("sendSynchronousRequestWithParameters  Got Error")
//                    DLog("got error")
                    DLog(error!.localizedDescription)
                    var msg = error!.localizedDescription
                    if msg == ""
                    {
                        msg = RQST_TIMES_OUT_MSG
                    }
                    DLog("\(RQST_TIMES_OUT_MSG)")
                    DispatchQueue.main.async {
                        let objAlertController = UIAlertController(title: nil, message: RQST_TIMES_OUT_MSG, preferredStyle: .alert)
                        
                        let OK = UIAlertAction(title: OK_BTN, style: .cancel, handler: { (UIAlertAction) in
                            ForceSTopIndicator()
                        })
                        objAlertController.addAction(OK)
                        if let val = UIApplication.topViewController()
                        {
                            if val is UIAlertController || indicator != nil
                            {
                                hideLoadingAlertWithPresentController(viewcontroller: objAlertController)
                            }
                        }
                    }
                }
                if let value = data{
                    responseData = value as NSData
                }
                
                if error != nil
                {
                    responseData = nil
                }
                semaphore.signal()
            }.resume()
            semaphore.wait()

            if UserDefaults.standard.value(forKey: "api_recall") != nil
            {
                api_recall = UserDefaults.standard.integer(forKey: "api_recall")
            }
            else
            {
                api_recall = 2
            }
        }while(responseData == nil && callCount < api_recall)
        
        stopJsonAsync = false
        return responseData
    }
    
    func baseAlertFunc() -> UIAlertController
    {
        if (baseAlert != nil)
        {
            baseAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        }
        return baseAlert!
    }
    
    func sendSynchronousRequestWithParameters11(_ dict : NSMutableDictionary, andPostData postData : NSData?) -> NSData?
    {
        var responseData: NSData? = nil
        stopJsonAsync = true
            responseData = nil
            DLog("Strt sending. Date== > \(Date())")
            // Make and set request data
            
            let url = dict["url"] as! String
            guard let endpoint = URL(string: url) else {
                DLog("Error creating endpoint")
                isCheckingFaxStatus = false
                return nil
            }
            var request = URLRequest(url: endpoint)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

            if let val = dict["request_time_out"] {
                request.timeoutInterval = val as! TimeInterval
            } else {
                
                if url == SEND_FAX_URL
                {
                    request.timeoutInterval = 1800
                }
                else
                {
                    request.timeoutInterval = TimeInterval(REQUEST_TIMEOUT_INTERVAL)
                }
            }
        
            if (dict["req_method"] as? String != nil){
                request.httpMethod = (dict["req_method"] as! String)
            }
            if (postData != nil)
            {
                request.httpBody = postData as? Data
            }
            let strLength =  "\((postData?.length)!)"
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.addValue("Content-Length", forHTTPHeaderField: strLength)
            request.addValue("Accept-Encoding", forHTTPHeaderField: "gzip")

            let configuration = URLSessionConfiguration.default
            let manqueue = OperationQueue.main
            let session = URLSession(configuration: configuration, delegate:self, delegateQueue: manqueue)
//            trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SENDING_START])
            trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_OUTGOING_FAX,GA_ACTION:SENDING_START])

            dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
                do
                {
                    if error != nil || data == nil{
                        DLog("got error")
                        DLog(error!.localizedDescription)
                        var msg = error!.localizedDescription
                        if msg == ""
                        {
                            msg = RQST_TIMES_OUT_MSG
                            DLog("\(RQST_TIMES_OUT_MSG)")
                        }
                        ForceSTopIndicator()
                        DispatchQueue.main.async(execute: {() in
                            let objAlertController = UIAlertController(title: nil, message: RQST_TIMES_OUT_MSG, preferredStyle: .alert)
                            let OK = UIAlertAction(title: OK_BTN, style: .cancel, handler: { (UIAlertAction) in
                                ForceSTopIndicator()
                            })
                            
                            objAlertController.addAction(OK)
                            if let topView = UIApplication.topViewController()
                            {
                                if indicator != nil || topView is UIAlertController
                                {
                                        hideLoadingAlertWithPresentController(viewcontroller: objAlertController)
                                }
                            }
                        })
                   }
                    if data != nil
                    {
                        let response = NSString.init(data: data! , encoding: String.Encoding.utf8.rawValue)
                        let dictResponse = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
                        DLog("SEND_FAX_URL Done.. == > \(dictResponse)")
//                        trackDataOnAnalytics(withData: [GA:GA,SCREEN_NAME:SENDING_DONE])
                        trackEventOnAnalytics(withData: [GA:GA,GA_CATEGORY:GA_OUTGOING_FAX,GA_ACTION:SENDING_DONE])
                        
                        if  wizardController == nil
                        {
                            WizardViewController().sentSuccessfullySendFaxData(dicServerResponse: dictResponse)
                        }
                        else
                        {
                            wizardController?.sentSuccessfullySendFaxData(dicServerResponse: dictResponse)
                        }
                    }
                }
                catch
                {
                    isCheckingFaxStatus = false 
                    hideLoadingAlert()
                }
            })
            dataTask?.resume()
        
        stopJsonAsync = false
        return responseData
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            DLog("Uploaded...\(totalBytesSent)/\(totalBytesExpectedToSend)")
            let progresss = Float(totalBytesSent/totalBytesExpectedToSend)
            progressView?.setProgress(Float(progresss), animated: true)
            progressView?.setNeedsDisplay()
            progressView?.setNeedsLayout()
    }
    
    func performDismiss()
    {
        NetworkActivityIndicatorManager.stop()
        self.baseAlert?.dismiss(animated: true, completion: nil)
        
    }
    
    func performDismissVC(_ vc : UIViewController)
    {
        NetworkActivityIndicatorManager.stop()
        self.baseAlert?.dismiss(animated: true, completion: nil)
        
    }
    
    func resendFromWidget()
    {
        let PID = URL_OUTER_APP_STRING.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        
        if (PID.characters.count) > 0
        {
            URL_OUTER_APP_STRING = ""
            if !networkAvailability()
            {
                alertNetworkNotAvailableTryAgain(controller: UIApplication.topViewController()!)
            }
            let outboundMessages = DataModel.sharedInstance.getOutBoundMessageByFolderId(Int(PID)!)
            if outboundMessages.count != 0
            {
//                showLoadingAlert(RESENDING_TITLE, networkIndicator: true)
                prepareSendFaxDataForServer(mode: SEND_FAX_MODE.RESESND_FAX.rawValue,outboundEntity: outboundMessages[0])
            }
        }
    }
    
    func loginFromWidget()
    {
        if let value = UIApplication.topViewController()
        {
            if UIApplication.topViewController() is LoginViewController
            {
                
            }
            else
            {
                URL_OUTER_APP_STRING = ""
                if let vc:LoginViewController = value.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController?
                {
                    vc.hidesBottomBarWhenPushed = true
                    value.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    //MARK: Push notification

    func SendDeviceLog()
    {
        
        if !networkAvailability(){
            if let value = UIApplication.topViewController(){
                DispatchQueue.main.async {
                    
                     if value is UIAlertController{
                        internetAlertCount = 0
                    }
                    else
                    {
//                        alertNetworkNotAvailableTryAgain(controller: value)
                    }
                }
            }
            return
        }
        var user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
        if user_id == nil
        {
            user_id = ""
        }

//        DLog("guid: \(user_id!)==\(device_id)==\(user_id!)==\(device_token)==\(OS_NAME_AND_VERSION)==\(timeZoneName)")
//        DLog("((Bundle.main.infoDictionary)? as! String): \(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String)")
        let params = String(format:"device_id=%@&user_id=%@&token=%@&os=%@&location=%@&app_version=%@" , arguments: [device_id, user_id!, device_token,OS_NAME_AND_VERSION,timeZoneName,Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String])
        let dict = NSMutableDictionary()
        dict.setValue(Device_Log, forKey: "url")
        dict.setValue(REQUEST_METHOD_POST, forKey: "req_method")
        self.sendAsynchronousRequestWithParameters(dict, andPostData: params.data(using: String.Encoding.utf8), completion: { data in
            
//            DLog("data in senddevice log: \(data)")
            if data != nil
            {
                do
                {
                    let dictResponse = try JSONSerialization.jsonObject(with: data as! Data, options: .mutableContainers) as! NSMutableDictionary
                    DLog("dictResponse: \(dictResponse)")
                }catch{
                    self.performDismiss()
                }
            }
        })
        
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
        
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle.main;
//        let modelURL = Bundle.main.urlForResource("iFax", withExtension: "mom")!
        let modelURL = Bundle.main.url(forResource: "iFax", withExtension: "mom")
        return NSManagedObjectModel(contentsOf: modelURL!)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        //      let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        if let url = getPathURLOfContainer()?.appendingPathComponent("SingleViewCoreData.sqlite"){
            var failureReason = "There was an error creating or loading the application's saved data."
            do {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            } catch {
                // Report any error we got.
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
                dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
                
                dict[NSUnderlyingErrorKey] = error as NSError
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                // Replace this with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                DLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
//                abort()
            }
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
                if self.managedObjectContext.hasChanges {
                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
//                        DLog("Unresolved error \(nserror), \(nserror.userInfo)")
                        //                    abort()
                    }
                }
    }
    
    
    func handleCurrentViewController(_ notification: Notification) {
        if ((notification.userInfo!["lastViewController"] ) != nil) {
            lastViewController = (notification.userInfo!["lastViewController"] as! UIViewController!)
        }
    }
    
    //MARK: touchID and PassCode ON/OFF
    func isPasscodeIsON()
    {
        hideLoadingAlert()
        let context = LAContext()
        var error: NSError?

        if UserDefaults.standard.object(forKey: TOUCH_ID) != nil && UserDefaults.standard.object(forKey: TOUCH_ID) as! String == "1"
        {
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                self.authenticateUser()
            }
            else
            {
                self.passCodeWithOnlyText()
            }
        }
        else
        {
            self.passCodeWithtext()
        }
    }
    
    func passCodeWithOnlyText()
    {
        let alertController = UIAlertController(title: AUTHENTICATION, message: PLEASE_ENTER_PASSCODE, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OK_BTN, style: .default) { (_) in
            //            if
            let field = alertController.textFields![0]
            //                {
            if field.text == UserDefaults.standard.object(forKey: PASSCODE_TEXT) as? String
            {
                alertController.dismiss(animated: true , completion: nil)
                if URL_OUTER_APP_STRING.contains("widgetResend")
                {
                    self.resendFromWidget()
                }
                else if URL_OUTER_APP_STRING.contains("widgetLogin")
                {
                    self.loginFromWidget()
                }
            }
            else{
                self.isPasscodeIsON()
            }
            //            } else {
            //             self.passCodeWithtext()
            //            }
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter passcode..."
            textField.isSecureTextEntry  = true
        }
        alertController.addAction(confirmAction)
        hideLoadingAlert()
        UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController)?.present(alertController, animated: true)
    }
    
    
    func passCodeWithtext()
    {
        let alertController = UIAlertController(title: AUTHENTICATION, message: PLEASE_ENTER_PASSCODE, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: OK_BTN, style: .default) { (_) in
//            if
                let field = alertController.textFields![0]
//                {
                if field.text == UserDefaults.standard.object(forKey: PASSCODE_TEXT) as? String
                {
                    alertController.dismiss(animated: true , completion: nil)
                    if URL_OUTER_APP_STRING.contains("widgetResend")
                    {
                        self.resendFromWidget()
                    }
                    else if URL_OUTER_APP_STRING.contains("widgetLogin")
                    {
                        self.loginFromWidget()
                    }
                }
                else{
                    self.passCodeWithtext()
                }
//            } else {
//             self.passCodeWithtext()
//            }
        }
        let touchID = UIAlertAction(title: TOUCH_ID_BTN, style: .default) { (_) in
            self.authenticateUser()
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter passcode..."
            textField.isSecureTextEntry  = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(touchID)
        hideLoadingAlert()
        UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController)?.present(alertController, animated: true)

    }
    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: { (success, authenticationError) in
                DispatchQueue.main.async {
                    if success {
//                        DLog("succesfully Registered in the App")
                        
                        if URL_OUTER_APP_STRING.contains("widgetResend")
                        {
                            self.resendFromWidget()
                        }
                        else if URL_OUTER_APP_STRING.contains("widgetLogin")
                        {
                            self.loginFromWidget()
                        }
                    } else {
                
                        switch authenticationError!._code
                        {
                        case LAError.systemCancel.rawValue:
                                self.isPasscodeIsON()
                            break
                        case LAError.userCancel.rawValue:
                           self.passCodeWithtext()
                            break
                        case LAError.userFallback.rawValue:
                            self.passCodeWithtext()
                            break
                        case LAError.touchIDNotAvailable.rawValue :
                            self.passCodeWithtext()
                            break
                        /// Authentication could not start, because Touch ID has no enrolled fingers.
                        case LAError.touchIDNotEnrolled.rawValue:
                            self.passCodeWithtext()
                            break
                        default:
                            if authenticationError!._code == -1000
                            {
                                self.self.passCodeWithOnlyText()
                            }
                            else
                            {
                                if #available(iOS 8, *)
                                {
                                    self.passCodeWithtext()
                                }
                                else
                                {
                                    self.isPasscodeIsON()
                                }
                            }
                            break
                        }
                    }
                }     
            })
        } else {
            let ac = UIAlertController(title: TOUCH_ID_NOT_AVILABLE_TITLE, message: TOUCH_ID_NOT_AVILABLE_MESSAGE, preferredStyle: .alert)
           ac.addAction(UIAlertAction(title: OK_BTN, style: .default){ (_) in
//                self.authenticateUser()
                self.isPasscodeIsON()
           })
            
           UIApplication.topViewController(base: UIApplication.shared.keyWindow?.rootViewController)?.present(ac, animated: true)
        }
    }
    

    //MARK: fetch inbound fax using fax numbers
    func getFax()
    {
        
//        let user_id = getValueFromUserDefault(key: DEFAULT_USERID) as? String
//        if user_id != nil
//        {
            if faxnumbers.count > 0
            {
                for i in 0..<faxnumbers.count
                {
                    if faxnumbers.count > 0
                    {
                        if let faxNumberDetails : [String:AnyObject] = faxnumbers[i] as [String:AnyObject]?
                        {
                            if faxNumberDetails["faxNumber"]  != nil && faxNumberDetails["username"]  != nil
                            {
                                setValueInUserDefault(key: "username", value: "\(faxNumberDetails["username"])", isSync: true)
                                self.GetListInboundFaxNumber(faxNumberDetails["faxNumber"] as! String, userName: faxNumberDetails["username"] as! String)
                            }
                        }
                    }
                }
            }
//        }
    }
    
    func defaultCover_Page()
    {
        for i in 0...5
        {
            let covername : String = defaultCoverPDF_Name[i]
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
            let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            
            if let dirPath          = paths.first
            {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(covername).png")
                if !FileManager.default.fileExists(atPath: imageURL.path)
                {
                    do
                    {
                        
                        let covername : String = defaultCoverPDF_Name[i]
                        let url = Bundle.main.url(forResource: covername, withExtension: "pdf")
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(covername).png")
                        if isThisForiPad == true
                        {
                           try UIImageJPEGRepresentation(imageFromPDF(url: url!, targetSize: CGSize(width:768 ,height: 1024) , PageNo: 1 )!, 2.0)?.write(to: imageURL)
                        }
                        else
                        {
                                try UIImagePNGRepresentation(imageFromPDF(url: url!, targetSize: CGSize(width:612 ,height: 792) , PageNo: 1 )!)?.write(to: imageURL)
                        }
                        
                    }catch {
                        print("image is not writing fail...!")
                    }
                }
            }
        }
    }
    
    func checkStaus()
    {
//            DLog("Appdele  -- > checkStaus()")
            checkStatusOfFaxes(faxStatus: [FAX_STATUS.SENDING.rawValue,FAX_STATUS.SENT.rawValue])
    }

 }
