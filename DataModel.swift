import Foundation
import CoreData
class DataModel: NSObject {
    
    static let sharedInstance = DataModel()
    let managedObjectContext : NSManagedObjectContext = {
        var managedObjectContext =  (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
        return managedObjectContext
    }()
    
    func saveContext(){
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    //MARK: OutBund Message methods
    func getOutBoundEntityObject() -> Outbound_messages {
        let outboundEntity = NSEntityDescription.insertNewObject(forEntityName: "Outbound_messages", into: managedObjectContext) as! Outbound_messages
        
        // get max folder id
        let folderID = getMaxFolderInOutBoundEntity()
        outboundEntity.folder_id = folderID
        outboundEntity.page_count = Int64(1)
        outboundEntity.fax_status = Int64(1)
        let currentDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let currentDateStr = dateFormatter.string(from: currentDate as Date)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTimeStr = timeFormatter.string(from: currentDate as Date)
        
        //NSDate properties
        if let value = convertStringToDate(dateString: (currentDateStr)){
            outboundEntity.date = value as NSDate
        }
        if let value = convertStringToTime(timeString: (currentTimeStr)){
            outboundEntity.time = value as NSDate
        }
        return outboundEntity
    }
    func getOutBoundFilesEntityObject() -> Outbound_message_files {
        let outboundFilesEntity = NSEntityDescription.insertNewObject(forEntityName: "Outbound_message_files", into: managedObjectContext) as! Outbound_message_files
        outboundFilesEntity.date = NSDate()
        return outboundFilesEntity
    }
    func getMaxFolderInOutBoundEntity() -> Int64 {
        var folderID: Int64 = 0
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "folder_id", ascending: false)]
        do {
            let fetchResults = try self.managedObjectContext.fetch(request)
            if fetchResults.count>0{
                let fetchResult : Outbound_messages = fetchResults.first!
                folderID = fetchResult.folder_id
                }
            
        } catch {
//            DLog("\(error)")
        }
       return folderID + 1
    }
    func getMaxFolderInBoundEntity() -> Int64 {
        var folderID: Int64 = 0
        let request: NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "folder_id", ascending: false)]
        do {
            let fetchResults = try managedObjectContext.fetch(request)
            if fetchResults.count>0{
                let fetchResult : Inbound_messages = fetchResults.first!
                if let id = fetchResult.folder_id as Int64?
                {
                    folderID = id
                }
            }
            
        } catch {
//            DLog("\(error)")
        }
        return folderID + 1
    }

    func getOutBoundMessages() -> [Outbound_messages]{
        var fetchResults : [Outbound_messages] = []
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
//        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "time", ascending: false)]
        request.predicate = NSPredicate(format: "fax_status = %d OR fax_status = %d OR fax_status = %d OR fax_status = %d",2,3,4,5)
        do {
            fetchResults = try managedObjectContext.fetch(request)
            
        } catch {
//            DLog("\(error)")
        }
        print(fetchResults)
        return fetchResults
    }
    
    
    func getOutBoundMessagesByNameStatus(_ sortWith : String) -> [Outbound_messages]{
        var fetchResults : [Outbound_messages] = []
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        request.predicate = NSPredicate(format: "fax_status = %d OR fax_status = %d", 1, 2)
        if sortWith == "Date"
        {
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "time", ascending: false)]

//            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
//            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        }
        else if sortWith == "Name"
        {
            request.sortDescriptors = [NSSortDescriptor(key: RECIPIENT_NAME, ascending: true)]
        }
        else
        {
            request.sortDescriptors = [NSSortDescriptor(key: "fax_status", ascending: true)]
        }
        
        do {
            fetchResults = try managedObjectContext.fetch(request)
            
        } catch {
//            DLog("\(error)")
        }
        return fetchResults
    }
    
    
    func getUnPaidUnsentFaxCount() -> Int{
        var fetchResults : [Outbound_messages] = []
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        request.predicate = NSPredicate(format: "fax_status = %d", 1)
        do {
            fetchResults = try managedObjectContext.fetch(request)
            
        } catch {
//            DLog("\(error)")
        }
        return fetchResults.count
    }
    
    func getLastUnPaidUnsentFax() -> [Outbound_messages]
    {
        var fetchResults : [Outbound_messages] = []
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "fax_status = %d", 1)
        request.sortDescriptors = [NSSortDescriptor(key: "folder_id", ascending: false)]
        do {
            fetchResults = try managedObjectContext.fetch(request)
        } catch {
//            DLog("\(error)")
        }
            return fetchResults
    }
    
    func getOutBoundMessageByFolderId(_ folder_id : Int) -> [Outbound_messages]
    {
        var fetchResults : [Outbound_messages] = []
        let request: NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        request.predicate = NSPredicate(format: "folder_id = %d", folder_id)
        do {
            fetchResults = try managedObjectContext.fetch(request)
            
        } catch {
//            DLog("\(error)")
        }
        return fetchResults
    }
    
    func getInBoundMessages() -> [Inbound_messages]{

        var fetchResults : [Inbound_messages] = []
        let request: NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "time", ascending: false)]
//        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        do {
            fetchResults = try self.managedObjectContext.fetch(request)
            
        } catch {
//            DLog("\(error)")
        }
        return fetchResults

    }
    
    // get all attechment files list for wizard screen
    func getAllAttechmentFileList(entityObject : Outbound_messages?) -> [URL]
    {
        if entityObject != nil{
            var fileUrls : [URL] = []
            var fetchResults : [Outbound_message_files] = []
            let request: NSFetchRequest<Outbound_message_files> = Outbound_message_files.fetchRequest()
            request.predicate = NSPredicate(format: "outboundMessage == %@", entityObject!)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            do {
                let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
                fetchResults = try managedObjectContext.fetch(request)
            } catch {
                DLog("\(error)")
            }
            let value = String((entityObject?.folder_id)!)
            DLog("value = \(value)")
            let documentsPath = getOutgoingPath()
            
            let folderPath : NSURL = (documentsPath?.appendingPathComponent(value as String))! as NSURL
            
            for fetchResult in fetchResults as [Outbound_message_files] {
                if let name = fetchResult.file_name{
                    let fileURL:URL = (folderPath.appendingPathComponent(name as String))!
                    fileUrls.append(fileURL)
                }
            }
            return fileUrls
        }
        return []
    }
    
    func fetchOutboundFaxesForFaxStatus(fax_status : Array<Int>) -> [Outbound_messages]
    {
        var result : [Outbound_messages] = []
        
        // Initialize Fetch Request
        let fetchRequest : NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        
        // Create Entity Request
        let entityDescription = NSEntityDescription.entity(forEntityName: "Outbound_messages", in: self.managedObjectContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        // Predicate
        var predicate = ""
        for i in 0..<fax_status.count
        {
            let status = String(fax_status[i])
            if i < fax_status.count-1
            {
                predicate = predicate + "fax_status=" + status + " OR "
            }
            else
            {
                predicate = predicate + "fax_status=" + status
            }
        }
        
        fetchRequest.predicate = NSPredicate(format: predicate)
        
        do
        {
            result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Outbound_messages]
            return result
        }
        catch
        {
            let fetchError = error as NSError
            DLog("\(fetchError)")
        }
        return []
    }
    
    func fetchSentUnsentFax(_ fax : Int) -> [Outbound_messages]
    {
        var result : [Outbound_messages] = []
        
        // Initialize Fetch Request
        let fetchRequest : NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "Outbound_messages", in: self.managedObjectContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        //Predicate
        if fax == FAX_STATUS.SENDING.rawValue
        {
            fetchRequest.predicate = NSPredicate(format: "fax_status = %d", 3)
        }
        else if fax == FAX_STATUS.RECEIVED_FAX.rawValue
        {
            fetchRequest.predicate = NSPredicate(format: "fax_status = %d", 4)
        }
        else if fax == FAX_STATUS.SENT.rawValue
        {
            fetchRequest.predicate = NSPredicate(format: "fax_status = %d", 5)
        }
        else if fax == FAX_STATUS.PAID_UNSENT.rawValue
        {
            fetchRequest.predicate = NSPredicate(format: "fax_status = %d OR fax_status = %d", 2, 3)
        }
        else
        {
            fetchRequest.predicate = NSPredicate(format: "fax_status = %d", 2)
        }
        
        do {
            result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Outbound_messages]
            return result
            
            
        } catch {
            let fetchError = error as NSError
            DLog("\(fetchError)")
        }
        return []
    }
    
    func fetchOutboundForServerId(_ server_id : Int64) -> [Outbound_messages]
    {
        var result : [Outbound_messages] = []
        
        // Initialize Fetch Request
        let fetchRequest : NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "Outbound_messages", in: self.managedObjectContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
//        server_id = 65
        fetchRequest.predicate = NSPredicate(format: "server_id = %d",server_id)
        
        do {
            result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Outbound_messages]
            return result
            
        } catch {
            let fetchError = error as NSError
            DLog("\(fetchError)")
        }
        return []
    }
    
    func fetchOutboundForHome() -> [Outbound_messages]
    {
        var result : [Outbound_messages] = []
        
        // Initialize Fetch Request
        let fetchRequest : NSFetchRequest<Outbound_messages> = Outbound_messages.fetchRequest()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "Outbound_messages", in: self.managedObjectContext)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        fetchRequest.predicate = NSPredicate(format: "fax_status = %d OR fax_status = %d OR fax_status = %d OR fax_status = %d", 2, 3, 4,5)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "time", ascending: false)]

        do {
            result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Outbound_messages]
            return result
            
            
        } catch {
            let fetchError = error as NSError
            DLog("\(fetchError)")
        }
        return []
    }
    func deleteOutgoingFax(_ object : [Outbound_messages])
    {
        for i in 0 ..< object.count
        {
            let folder_id = object[i].folder_id
            var path = getOutgoingPath()
            path = path?.appendingPathComponent("\(folder_id)")
            do {
                try FileManager.default.removeItem(at: path!)
            }
            catch let error as NSError {
                DLog("Ooops! Something went wrong: \(error)")
            }
            self.managedObjectContext.delete(object[i])
            self.saveContext()
        }
    }
    
    func deleteIncomingFax(_ object : [Inbound_messages])
    {
        for i in 0 ..< object.count
        {
            let folder_id = object[i].folder_id
            var path = getIncomingPath()
            path = path?.appendingPathComponent("\(folder_id)")
            do {
                try FileManager.default.removeItem(at: path!)
            }
            catch let error as NSError {
                DLog("Ooops! Something went wrong: \(error)")
            }
            self.managedObjectContext.delete(object[i])
            self.saveContext()
        }
    }
    func fetchAllInboundTransctions() -> [Inbound_transactions]
    {
        var fetchResults : [Inbound_transactions] = []
        let request: NSFetchRequest<Inbound_transactions> = Inbound_transactions.fetchRequest()
        do {
            fetchResults = try managedObjectContext.fetch(request)
            
        } catch {
            DLog("\(error)")
        }
        return fetchResults
    }
    func deleteInboundTransction(_ predicate: NSPredicate){
        DLog("deleteInboundTransction : \(predicate)")
        var result: [Transactions] = []
        let fetchRequest: NSFetchRequest<Transactions> = Transactions.fetchRequest()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Transactions", in: self.managedObjectContext)
        fetchRequest.entity = entityDescription
        fetchRequest.predicate = predicate
        
        do{
            result = try self.managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Transactions]
            DLog("Found Inbound Transction record: \(result)")
            for object in result {
                if let value = object.inbound_transaction{
                    self.managedObjectContext.delete(value)
                    self.saveContext()
                    DLog("Delete Inbound Transction")
                }
                
            }
            
        } catch {
            let fetchError = error as NSError
            DLog("\(fetchError)")
        }
        
    }
    func getMaxTransctionIdFromInboundFax(_ faxNumber:String) -> Int64{
        var transactionId:Int64 = 0
        let request: NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
        let entityDescription = NSEntityDescription.entity(forEntityName: "Inbound_messages", in: self.managedObjectContext)
        
        // Configure Fetch Request
        request.entity = entityDescription
        request.predicate = NSPredicate(format: "self.receiver_fax_number contains[c] %@",faxNumber)
        request.sortDescriptors = [NSSortDescriptor(key: "folder_id", ascending: false)]
        do {
//            request.fetchLimit = 1
            let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
            let fetchResults = try managedObjectContext.fetch(request)
            if fetchResults.count>0{
                let fetchResult : Inbound_messages = fetchResults.first!
                if fetchResult.transaction_id != 0
                {
                    transactionId = fetchResult.transaction_id
                }
            }
            
        } catch {
            DLog("\(error)")
        }
        return transactionId
    }
    
    func removeAllInBoundDataFromDatabase()
    {
        let fetchRequest: NSFetchRequest<Inbound_messages> = Inbound_messages.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.includesPropertyValues = false
        
        do {
            let inbound_Directory = getIncomingPath()
            try FileManager.default.removeItem(at: inbound_Directory!)
            
            let items = try managedObjectContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [NSManagedObject]
            if items.count > 0
            {
                for item in items {
                    let inbound_Directory = getIncomingPath()
                    try FileManager.default.removeItem(at: inbound_Directory!)
                    managedObjectContext.delete(item)
                }
                
                // Save Changes
                try managedObjectContext.save()
            }
        } catch {
            // Error Handling
            // ...
        }
    }
    
    //MARK:- Sync data
    func addOrUpdateSyncData(_dates : NSMutableDictionary)
    {
        var fetchResult : [Last_sync_detail] = []
        let fetchReq : NSFetchRequest<Last_sync_detail> = Last_sync_detail.fetchRequest()
        do{
            fetchResult = try managedObjectContext.fetch(fetchReq)
        }
        catch{
            DLog("\(error)")
        }
        
        if fetchResult.count>0 // Update the data
        {
            
            let last_sync = fetchResult[0]
            if let dateValues = _dates["credit_package"] as? NSDate
            {
                last_sync.credit_package_server_date = dateValues
            }
            
            if let dateValues = _dates["inbound_price"] as? NSDate
            {
                last_sync.inbound_price_server_date = dateValues
            }
            
            if let dateValues = _dates["outbound_price"] as? NSDate
            {
                last_sync.outbound_price_server_date = dateValues
            }
           self.saveContext()
        }
        else
        {
            let lastSyncEntity  = NSEntityDescription.insertNewObject(forEntityName: "Last_sync_detail", into: managedObjectContext) as! Last_sync_detail
            if let dateValues = _dates["credit_package"] as? NSDate
            {
                lastSyncEntity.credit_package_server_date = dateValues
            }
            
            if let dateValues = _dates["inbound_price"] as? NSDate
            {
                lastSyncEntity.inbound_price_server_date = dateValues
            }
            if let dateValues = _dates["outbound_price"] as? NSDate
            {
                lastSyncEntity.outbound_price_server_date = dateValues
            }
                self.saveContext()
        }
    }
    
    func fetchServerSyncData() -> [Last_sync_detail]
    {
        var result: [Last_sync_detail] = []
        let request : NSFetchRequest <Last_sync_detail> = Last_sync_detail.fetchRequest()
        do{
            result = try managedObjectContext.fetch(request)
        }
        catch
        {
            DLog("\(error)")
            
        }
        return result
    }
    
    func syncDataStatusOf(syncName : Int) -> Bool
    {
        let syncObjectArr = DataModel.sharedInstance.fetchServerSyncData() as [Last_sync_detail]
        var serverDataUpdate = false
        if syncObjectArr.count > 0
        {
            let syncObject  = syncObjectArr[0]
            var server_date: NSDate?
            var local_date: NSDate?
            if syncName == SYNC_DATA.OUTBOUND_FAX.rawValue // Outbound fax price
            {
                local_date =  syncObject.outbound_price_local_date
                server_date =  syncObject.outbound_price_server_date
            }
            else if syncName == SYNC_DATA.CREDIT_PACKAGE.rawValue // Credit Package
            {
                local_date =  syncObject.credit_package_local_date
                server_date =  syncObject.credit_package_server_date
            }
            else if syncName == SYNC_DATA.INBOUND_FAX.rawValue // Inbound fax price
            {
                local_date =  syncObject.inbound_price_local_date
                server_date =  syncObject.inbound_price_server_date
            }
            
            
            if (local_date == nil || server_date == nil)
            {
                serverDataUpdate = true
            }
            else if (local_date != nil && server_date != nil)
            {
                if (!(server_date?.isEqual(to: local_date as! Date))!)
                {
                    serverDataUpdate = true
                }
            }
            else
            {
                serverDataUpdate = true
            }
        }
        else
        {
            serverDataUpdate = true
        }
        return serverDataUpdate
    }
}
