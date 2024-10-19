public class InvoiceController {
    public String originRecord { get; set; }
    public String account { get; set; }
    public Date invoiceDate { get; set; }
    public Date invoiceDueDate { get; set; }
    public String childRelationshipName { get; set; }
    public String lineItemDescription { get; set; }
    public Integer lineItemQuantity { get; set; }
    public Decimal lineItemUnitPrice { get; set; }
    
    
    public String jsonResponse { get; set; }
    
    
    public InvoiceController() {
        originRecord = ApexPages.currentPage().getParameters().get('origin_record');
        account = ApexPages.currentPage().getParameters().get('account');
        invoiceDate = Date.valueOf(ApexPages.currentPage().getParameters().get('invoice_date'));
        invoiceDueDate = Date.valueOf(ApexPages.currentPage().getParameters().get('invoice_due_date'));
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        lineItemDescription = ApexPages.currentPage().getParameters().get('line_item_description');
        lineItemQuantity = Integer.valueOf(ApexPages.currentPage().getParameters().get('line_item_quantity'));
        lineItemUnitPrice = Decimal.valueOf(ApexPages.currentPage().getParameters().get('line_item_unit_price'));
    }
    
    
    
    public void generateInvoiceJSON() {
        
        Opportunity opp = [SELECT Id, Name, CloseDate, Account.Name FROM Opportunity WHERE Id = :originRecord];
        List<OpportunityLineItem> lineItems = [SELECT Quantity, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        
        Map<String, Object> invoiceMap = new Map<String, Object>();
        invoiceMap.put('InvoiceNumber', '0000000'); 
        invoiceMap.put('ContactId', '0000000'); 
        invoiceMap.put('Date', opp.CloseDate);
        invoiceMap.put('DueDate', opp.CloseDate.addDays(30)); 
        
        List<Map<String, Object>> lineItemList = new List<Map<String, Object>>();
        for (OpportunityLineItem lineItem : lineItems) {
            Map<String, Object> itemMap = new Map<String, Object>();
            itemMap.put('Description', 'Product Description'); 
            itemMap.put('Quantity', lineItem.Quantity);
            itemMap.put('UnitAmount', lineItem.UnitPrice);
            itemMap.put('LineAmount', lineItem.TotalPrice);
            lineItemList.add(itemMap);
        }
        
        invoiceMap.put('LineItems', lineItemList);
        jsonResponse = JSON.serialize(invoiceMap);
    }
    
    public String getJsonResponse() {
        return jsonResponse;
    }
    
    
    
    
    
    public PageReference createInvoice() {
        Opportunity opp = [SELECT Id, AccountId, CloseDate, Name FROM Opportunity WHERE Id = :originRecord];
        DateTime invoiceDate = DateTime.newInstance(opp.CloseDate, Time.newInstance(0, 0, 0, 0)); 
        DateTime dueDate = invoiceDate.addDays(30);
        
        String invoicePayload = '{' +
            '"BillingAccountId": "' + opp.AccountId + '",' +
            '"InvoiceDate": "' + invoiceDate.format('yyyy-MM-dd') + '",' +
            '"DueDate": "' + dueDate.addDays(30).format('yyyy-MM-dd') + '",' +
            '"Status": "Draft"' +
            '}';
        
        System.debug('Invoice Payload: ' + invoicePayload);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/sobjects/Invoice/');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(invoicePayload);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 201) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String invoiceId = (String) jsonResponse.get('id');
            
            PageReference pageRef = new PageReference('/' + invoiceId);
            pageRef.setRedirect(true);
            return pageRef;
        }else if (res.getStatusCode() != 201) {
            System.debug('Error creating Invoice: ' + res.getStatus() + ' - ' + res.getBody());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating Invoice: ' + res.getStatus() + ' - ' + res.getBody()));
            return null;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error creating Invoice: ' + res.getStatus()));
            return null;
        }
    }
}
