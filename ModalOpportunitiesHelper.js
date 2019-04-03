({
    getOpportunityList: function (component) {
        var action = component.get('c.getOpportunities');
        action.setParams({
            relatedId: component.get("v.controller.relatedId"),
            currentOppId: component.get("v.recordId")
        });
        action.setCallback(this, function (actionResult) {
            component.set('v.opportunities', actionResult.getReturnValue());
            var opportunitiesList = component.get("v.opportunities");
            var sum = 0;
            opportunitiesList.forEach(element => {
                sum += element.Amount;
            });
            sum += component.get("v.controller.currentOpportunityAmount");
            component.set("v.sum", sum); // Total amount of related Opportunities
        });
        $A.enqueueAction(action);
    }
})