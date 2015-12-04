trigger FieldHistoryTrackSettingTrigger on FieldHistoryTrackingSetting__c (after insert, after update) {
if(Trigger.isAfter){
 if(Trigger.isInsert || Trigger.isUpdate){
         HandlerFieldHistoryTrack objFieldHistory = new HandlerFieldHistoryTrack();
         objFieldHistory.createDynamicTrigger(Trigger.new,UserInfo.getSessionId());   // update /Create  trigger
         objFieldHistory.changeFHTDataHolderSetting(Trigger.new);      // update setting into dataHolder object
 
 }
}
}