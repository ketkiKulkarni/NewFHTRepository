Trigger AccountHistoryTrackTrigger On Account (after Update) { 
 if(trigger.isAfter && trigger.isUpdate){
 Set <String> setEle = new Set<String>();
setEle.add('Fax');
if(setEle.size()>0){
FHT_StoreHistoryDataHandler objDataHandler = new FHT_StoreHistoryDataHandler();
objDataHandler.storeHistoryData(trigger.newMap, trigger.oldMap ,setEle, 'Account','Account(Account)');
}
}
}