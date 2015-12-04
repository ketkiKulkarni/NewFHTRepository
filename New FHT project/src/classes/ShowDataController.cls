public with sharing class ShowDataController {
    public string objects{get;set;}
    public string selectedFields{get;set;}
    public set<string> allObjList=new set<string>();
    public Boolean showRecords{get;set;}
    public list<String> FieldDataTrackList{get;set;}
    public map<String,list<String>> MapOfFieldDataTrack{get;set;}
    public list<FHTDataHolder__c> showFHTDataList{get;set;}
    public set<String> keyValues{get;set;}
    public list<String> mapvalues{get;set;}
    public map<String,list<String>> mapOfUpdateRecords{get;set;}
    public List<wrapperClass> wrapList {get; set;}
    public string base64text {get; set;}
    
    public ShowDataController() {
        showFHTDataList= new list<FHTDataHolder__c>();
        keyValues = new set<String>();
        mapvalues = new list<String>();
        wraplist = new  List<wrapperClass>();
    } 
    public List<SelectOption> getobjitems() {    
            list<FHTDataHolder__c> listObj = new  list<FHTDataHolder__c>();
            List<SelectOption> options = new List<SelectOption>();
            set<String> setObj = new set<String>();
            listObj = [Select Object_Label__c From FHTDataHolder__c WHERE IsObectCurrentlySelected__c=:true];   
            for(integer i=0;i<listObj.size();i++){
                 setObj.add(listObj[i].Object_Label__c);  
            }
            options.add(new SelectOption('','--None--'));
            for(String objType : setObj ) {
                options.add(new SelectOption(objType,objType));
            }
            options.sort();
            return options; 
    }  
    
    public List<SelectOption> getFields()
    {
       list<FHTDataHolder__c> listObj = new  list<FHTDataHolder__c>();
       List<SelectOption> options = new List<SelectOption>();
       listObj =[Select Field_Name__c From FHTDataHolder__c 
                 WHERE Object_Label__c =:objects 
                 AND IsFieldCurrentlySelected__c=:true];
       options.add(new SelectOption('--None--' ,'--None--'));
       for(FHTDataHolder__c obj : listObj)
       {
           options.add(new SelectOption(obj.Field_Name__c ,obj.Field_Name__c));
       }
       system.debug('==Selected objects fields =='+ options);
       return options;
    }
    
    public PageReference getshowFHTDataList() {
        MapOfFieldDataTrack = new map<String,list<String>>();
        mapOfUpdateRecords = new map<String,list<String>>();
        mapvalues = new list<String>();
        wraplist = new  List<wrapperClass>();
        try {         
            Attachment a = [Select ParentId, Body , Id From Attachment 
                                          where ParentId IN (Select Id
                                                             From FHTDataHolder__c 
                                                             where Object_Label__c =:objects
                                                             and Field_Name__c=:selectedFields) 
                                         and Name like 'FHTData%' limit 1];
            base64text= a.body.toString();  
       
        }
        catch(Exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error,'No file found');
            ApexPages.addMessage(msg);
            return null;   
        }
        showFHTDataList = [Select Object_Name__c, Name, Id, Field_Name__c, FieldDataTrack__c 
                           From FHTDataHolder__c 
                           where Object_Label__c =:objects
                           and Field_Name__c=:selectedFields];
        for(FHTDataHolder__c o: showFHTDataList) {
            if(o.Field_Name__c !=null){
                if(!MapOfFieldDataTrack.containsKey(o.Field_Name__c)) {
                    MapOfFieldDataTrack.put(o.Field_Name__c,new list<String>());
                }
                MapOfFieldDataTrack.get(o.Field_Name__c).addAll(base64text.split('±'));
            }
        }   
        keyValues = MapOfFieldDataTrack.keySet();
        for(string str:keyValues) {
            mapvalues.addAll(MapOfFieldDataTrack.get(str));
        }
        /*for(string s : mapvalues){
            string[] mystring =s.split('»');
            wrapList.add(new wrapperClass(mystring[0].remove('"'),mystring[1],mystring[2].remove('"')));
        }
        */
        for(string s : mapvalues){
            string[] mystring =s.split('»');
            Datetime  strDate = Datetime.valueOf(mystring[2].remove('"')); 
            strDate.format();
            //string  strDate = string.valueOf(mystring[2].remove('"'));
            wrapList.add(new wrapperClass(strDate,mystring[0].remove('"'),mystring[1]));
            system.debug('========='+strDate+' Orignal data Value='+mystring[2].remove('"')+'    String'+s);
        }
        wrapList.sort();
        return null;
    }
  
    
   
     public class wrapperClass implements comparable {
        public string updateRec {get;set;}
        public string userId {get;set;}
        public DateTime lstmodifiedDate {get;set;} 
        
        public  wrapperClass(){
        }
       public wrapperClass(DateTime lstmodifiedDate,String updateRec, String userId) {
            this.updateRec = updateRec;
            this.userId = userId;
            this.lstmodifiedDate = lstmodifiedDate;
        }
        public Integer compareTo(Object ObjToCompare) {
        wrapperClass that = (wrapperClass)ObjToCompare;  
        Integer returnValue = 0;  
        if ( this.lstmodifiedDate > that.lstmodifiedDate) { 
            returnValue = -1;
        } else if ( this.lstmodifiedDate < that.lstmodifiedDate) {
            returnValue = 1; 
        }
             return returnValue;
  
        }
     }
     public PageReference refresh() {
        wrapList.clear();
        return null;
        system.debug('My changes');
     }
     
}