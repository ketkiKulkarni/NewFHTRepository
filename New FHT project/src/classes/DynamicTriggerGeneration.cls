global with sharing class DynamicTriggerGeneration 
{
    @future(callout=true)
    public static void webServiceMethodOfCreateDynamicTrigger(string sobjname,string sobjectLabel,String selectedFields,string sessionId)
    { 
      list<string> lstSelectedFields = new list<string>();
      set<String> setSelectedFields;
      String elements ='Set <String> setEle = new Set<String>();\\n';
      if(selectedFields!=null && selectedFields!='')
      {
        lstSelectedFields = selectedFields.split(','); 
        setSelectedFields = new set<String>(lstSelectedFields);     
        for(String objEle : setSelectedFields){
          elements += 'setEle.add(' + '\'' + objEle + '\'' + ');\\n';
        }
      }
      elements+='if(setEle.size()>0){\\n' ;
      string strTriggerName = sobjname.remove('__')+'HistoryTrackTrigger';
      String strTriggerBody='(after Update) { \\n if(trigger.isAfter && trigger.isUpdate){\\n ';
      strTriggerBody +=elements;
      strTriggerBody += 'FHT_StoreHistoryDataHandler objDataHandler = new FHT_StoreHistoryDataHandler();\\n';
      strTriggerBody +='objDataHandler.storeHistoryData(trigger.newMap, trigger.oldMap ,setEle, ' + '\'' + sobjname + '\''+','+ '\'' + sobjectLabel + '\'' + ');\\n';
      strTriggerBody +='}\\n}\\n}\\n';
         
      String finalbody = 'Trigger '+strTriggerName+' On '+ sobjname + ' ' + strTriggerBody; 
      String StrJson = '{ "Name" : "'+strTriggerName +' ",'
            + '"TableEnumOrId" : "'+sobjname+'",'
            + '"Body" : " '+ finalbody +' "}' ;
         
      if(!checkTriggerExistOrNot(strTriggerName))
      {
         CreateTrigger(StrJson,sessionId);
      }
      else
      {
        updateTrigger(finalbody,sessionId,strTriggerName);
        system.debug('Trigger already exist.... and it is updated.... ');
      } 
    }
    public static Boolean checkTriggerExistOrNot(String triggerName)
    {
        List<ApexTrigger> lstTrigger=new List<ApexTrigger>();
        lstTrigger=[select id,name from ApexTrigger WHERE name =:triggerName]; 
        if(lstTrigger.size()!=0)
        return true;
        else
        return false;
    } 
   
    public static void createTrigger(string StrJson,string sessionId)
    {
        try {
        Httprequest req = new HttpRequest();
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v34.0/sobjects/ApexTrigger'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer  ' +sessionId);
        req.setBody(StrJson);          
         
        Http httpReq = new Http();
        HttpResponse res = httpReq.send(req);
        }
        catch(Exception e){
        
        }
        //System.debug('--------'+res.getBody());
    }
    public static void updateTrigger(string finalbody,string sessionId,string triggerName)
    {
        try{
        Httprequest req =new HttpRequest();
        Http httpReq =new Http();
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v28.0/tooling/sobjects/MetadataContainer/');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','Bearer ' + sessionId);
        req.setMethod('POST');
        String strMetadataContainerName='TgrMetCon'+DateTime.now();
        req.setBody('{"Name":"'+strMetadataContainerName +' "}');
        HttpResponse res = httpReq.send(req);
        String resBody = res.getBody();
        Map<String,Object> rmp = (Map<String,Object>)JSON.deserializeuntyped(resBody);
        String cid = (String)rmp.get('id');
        
        List<ApexTrigger> lstTrigger=new List<ApexTrigger>();
        lstTrigger=[select id,name from ApexTrigger WHERE name =:triggerName];
        
        String triggerid=lstTrigger[0].id ;    
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v28.0/tooling/sobjects/ApexTriggerMember/');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','Bearer ' +sessionId);
        req.setMethod('POST');
        
        String StrJson = '{ "MetadataContainerId" : "'+cid +' ",'
            + '"ContentEntityId" : "'+triggerid+'",'
            + '"Body" : " '+ finalbody +' "}' ;
        req.setBody(StrJson);
        
        res = httpReq.send(req);        
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v28.0/tooling/sobjects/ContainerAsyncRequest/');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','OAuth ' + sessionId);
        req.setMethod('POST');
        req.setBody('{"MetadataContainerId" : "'+cid +' ", "isCheckOnly": "false"}');
        res = httpReq.send(req);
        }
        catch(Exception e){
        
        }   
    }   
}