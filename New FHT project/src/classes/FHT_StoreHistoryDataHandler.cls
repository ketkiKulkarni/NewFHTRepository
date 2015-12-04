public with sharing class FHT_StoreHistoryDataHandler {
public static Map<ID,User> MapUser=new Map<ID,User>([SELECT ID,Name from User]);
public void storeHistoryData(Map<id,SObject> lstNewAcc,Map<id,SObject> lstOldAcc,Set<string> selectedFields,string ObjectName,string sobjectLabel)
{
    SObjectType ObjectType = Schema.getGlobalDescribe().get(ObjectName);
    Map<String,Schema.SObjectField> mapFields = ObjectType.getDescribe().fields.getMap();
    Map<string,FHTDataHolder__c> mapSavedObjectFields =new Map<string,FHTDataHolder__c>();
    Map<string,FHTDataHolder__c> FHTDataHolderWithAttachment = new Map<string,FHTDataHolder__c>();
    List<ID> idList=new List<ID>();
    List<Attachment> ListAttachment=new List<Attachment>();
    string fieldDataTrackAttachmentBody ;
    List<Attachment> updateAttachmentList=new List<Attachment>();
    for(FHTDataHolder__c obj:[SELECT Field_Name__c,
                              Object_Name__c,
                              FieldDataTrack__c,
                              Object_Label__c,
                              IsFieldCurrentlySelected__c,
                              IsObectCurrentlySelected__c
                              FROM FHTDataHolder__c
                              WHERE Object_Name__c=:ObjectName
                              AND Field_Name__c IN:selectedFields])
    {
        mapSavedObjectFields.put(obj.Field_Name__c,obj); 
        idList.add(obj.id);
    }
    Map<id,Attachment> mapAtt =new Map<id,Attachment>();
    for(Attachment a:[SELECT id,parentid,body FROM Attachment WHERE parentid IN :idList AND Name like 'FHTData%'])
    {
        mapAtt.put(a.parentid,a);
    }   
    for(string selectedField:selectedFields) {                      //to iterate all selected fields
        if(mapSavedObjectFields.containsKey(selectedField) && mapAtt.containsKey(mapSavedObjectFields.get(selectedField).id))   {
            Attachment objAt;
            objAt=mapAtt.get(mapSavedObjectFields.get(selectedField).id); 
            fieldDataTrackAttachmentBody=objAt.body.toString();
            for(SObject record: lstNewAcc.values()) {                     //iterate all trigger.new records
                Schema.SObjectField field = mapFields.get(selectedField);
                if(record.get(field) != lstOldAcc.get(record.id).get(field)) {
                    fieldDataTrackAttachmentBody=fieldDataTrackAttachmentBody+createFieldDataTrack(string.valueOF(lstOldAcc.get(record.id).get(field)),
                                                                                                   string.valueOf(record.get(field)),
                                                                                                   string.valueOF(record.get('LastModifiedById')),
                                                                                                   (DateTime)record.get('LastModifiedDate'),
                                                                                                   ObjectName,
                                                                                                   selectedField);                                                                     
                }
            }
            if(fieldDataTrackAttachmentBody!=objAt.body.toString()) {    // update if values diffrent
                objAt.body=blob.valueOf(fieldDataTrackAttachmentBody);
                updateAttachmentList.add(objAt);
            }
            system.debug('Hello 1');
        }
        // if attachment is deleted for dataHolder record
        else if(mapSavedObjectFields.containsKey(selectedField) && !mapAtt.containsKey(mapSavedObjectFields.get(selectedField).id)) {
            fieldDataTrackAttachmentBody='';
            for(SObject record: lstNewAcc.values()) {                     //iterate all trigger.new records
                Schema.SObjectField field = mapFields.get(selectedField);
                if(record.get(field) != lstOldAcc.get(record.id).get(field)) {
                    fieldDataTrackAttachmentBody=fieldDataTrackAttachmentBody+createFieldDataTrack(string.valueOF(lstOldAcc.get(record.id).get(field)),
                                                                                                   string.valueOf(record.get(field)),
                                                                                                   string.valueOF(record.get('LastModifiedById')),
                                                                                                   (DateTime)record.get('LastModifiedDate'),
                                                                                                   ObjectName,
                                                                                                   selectedField);
                }
            }
            Attachment objAtt=new Attachment();
            objAtt.body=blob.valueOf(fieldDataTrackAttachmentBody);       
            objAtt.ParentId =mapSavedObjectFields.get(selectedField).id ;
            objAtt.name='FHTData'+mapSavedObjectFields.get(selectedField).id;
            objAtt.ContentType = 'text/plain; charset=UTF-8';
            objAtt.IsPrivate = false;
            ListAttachment.add(objAtt);
             system.debug('Hello 2');
        }
        //Create new dataHolder record and Attachments
        else {   
            FHTDataHolder__c  obj1=new FHTDataHolder__c();
            fieldDataTrackAttachmentBody ='';
            for(SObject record: lstNewAcc.values()) {                    //iterate all trigger.new records
                Schema.SObjectField field = mapFields.get(selectedField);
                if(record.get(field) != lstOldAcc.get(record.id).get(field)) {
                    obj1.Name=ObjectName+'.'+selectedField;
                    obj1.IsFieldCurrentlySelected__c=true;
                    obj1.IsObectCurrentlySelected__c=true;
                    obj1.Field_Name__c=selectedField;
                    obj1.Object_Name__c=ObjectName;
                    obj1.Object_Label__c=sobjectLabel;
                    system.debug('%%%%%%%'+obj1);
                    fieldDataTrackAttachmentBody=fieldDataTrackAttachmentBody+createFieldDataTrack(string.valueOF(lstOldAcc.get(record.id).get(field)),
                                                                                                   string.valueOf(record.get(field)),
                                                                                                   string.valueOF(record.get('LastModifiedById')),
                                                                                                   (DateTime)record.get('LastModifiedDate'),
                                                                                                   ObjectName,
                                                                                                   selectedField);
                }
            }
            if(fieldDataTrackAttachmentBody !='') {
            FHTDataHolderWithAttachment.put(fieldDataTrackAttachmentBody,obj1);
            }
        }
        
    }
    try{
    update updateAttachmentList;
    }
    catch(Exception e)
    {}
    try{
    insert FHTDataHolderWithAttachment.values();
    }
    catch(Exception e)
    {}
    //create attachments for dataHolder records
    for(String attBody : FHTDataHolderWithAttachment.keySet()) {
        Attachment at = new Attachment(); 
        at.body=blob.valueOf(attBody);       
        at.ParentId = FHTDataHolderWithAttachment.get(attBody).Id;
        at.name='FHTData'+FHTDataHolderWithAttachment.get(attBody).Id;
        at.ContentType = 'text/plain; charset=UTF-8';
        at.IsPrivate = false;
        ListAttachment.add(at);
        //      
    }
    try{
    insert ListAttachment;
    }
    catch(Exception e)
    {}
}
public static String createFieldDataTrack(string PreviousValue,string newValue,string userID,DateTime modifiedDate,string ObjectName,string selectedField)
{
    string userName=getUserNameFromID(userID);
    String userContextModifiedDate=string.valueOf(modifiedDate);                        
    string FieldDataTrack='"'+'Changed '+ ObjectName+' '+selectedField+' from '+ PreviousValue+' to '+newValue+'»'+userName+'»'+userContextModifiedDate+'"±';
    return FieldDataTrack;
}
public static string getUserNameFromID(string userID)
{
    User u=MapUser.get(userID);
    return u.name;
}
}