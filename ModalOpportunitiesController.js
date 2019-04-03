({
    openModel: function (component, event, helper) {
        var action = component.get('c.currentOpportunityInfo');
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.controller', response.getReturnValue());
                var currentOppIsAlreadySplit = component.get("v.controller.isAlreadySplit");
                if (currentOppIsAlreadySplit) {
                    component.set("v.alreadySplit", true);
                } else {
                    component.set("v.alreadySplit", false);
                }
                component.set("v.isOpen", true);
                component.set("v.displayConfigTab", false);
                component.set("v.isFinished", false);
            }
        });
        $A.enqueueAction(action);
    },

    openRelatedModel: function (component, event, helper) {
        component.set("v.isRelatedOpen", true);
        helper.getOpportunityList(component);
    },

    closeRelatedModel: function (component, event, helper) {
        component.set("v.isRelatedOpen", false);
    },

    closeModel: function (component, event, helper) {
        component.set("v.isOpen", false);
        component.set("v.tabId", '1');

        var splits = component.get("v.divisions");
        for (var i = 0; i < splits; i++) {
            if (component.find("date" + i) != null) component.find("date" + i).destroy();
            if (component.find("amount" + i) != null) component.find("amount" + i).destroy();
        }
    },

    tab1Active: function (component, event, helper) {
        component.set("v.isFinished", false);
        component.set("v.body", []);
        component.set("v.displayConfigTab", false);
    },

    tab2Active: function (component, event, helper) {
        component.set("v.isFinished", true);
    },

    navigateToRecord: function (component, event, helper) { //Navigate the user to the record when ID is clicked
        var idx = event.currentTarget;
        var id = idx.dataset.value;
        var navEvent = $A.get("e.force:navigateToSObject");
        navEvent.setParams({
            recordId: id,
            slideDevName: "detail"
        });
        navEvent.fire();
    },

    nextTab: function (component, event, helper) {

        var splits = component.get("v.divisions");
        if (splits > 1) {
            var activeTab = component.get("v.tabId");
            component.set("v.displayConfigTab", true);
            if (activeTab == '1') {
                component.find("tabs").set("v.selectedTabId", '2');
                component.set("v.tabId", '2');
                component.set("v.isFinished", true);

                var amount = component.get("v.controller.currentOpportunityAmount");
                var closeDate = component.get("v.controller.currentOpportunityCloseDate");

                $A.createComponents([ //Creating the first row to display general info of current opportunity
                    ["ui:outputText",
                        {
                            "value": 'Total Revenue: ' + amount,
                        }
                    ], ["ui:outputText",
                        {
                            "value": 'Overall Close Date: ' + closeDate
                        }
                    ], ["lightning:layoutItem",
                        {
                            "size": "12"
                        }
                    ], ["aura:html",
                        {
                            tag: "div",
                            HTMLAttributes: { "id": "Temp", "style": "width:100%; height:2px; background:black;" }
                        }
                    ], ["lightning:layoutItem",
                        {
                            "size": "12"
                        }]
                ], function (components, status, errorMessage) {
                    if (status === "SUCCESS") {
                        var body = component.get("v.body");
                        components.forEach(function (item) {
                            body.push(item); //Adding the components to the body
                        });
                        component.set("v.body", body);
                    }
                    else if (status === "INCOMPLETE") { console.log("No response from server or client is offline.") }
                    else if (status === "ERROR") { console.log("Error: " + errorMessage); }
                });
                for (var i = 0; i < splits; i++) {
                    $A.createComponents([
                        ["ui:outputText",
                            {
                                "value": (i + 1) + "."
                            }
                        ], ["ui:inputText",
                            {
                                "aura:id": "amount" + i,
                                "labelClass": "slds-form-element__label",
                                "placeholder": "Amount",
                                "label": "Revenue",
                                "class": "slds-input"
                            }
                        ], ["ui:inputDate",
                            {
                                "aura:id": "date" + i,
                                "labelClass": "slds-form-element__label",
                                "placeholder": "Close Date",
                                "label": "Close Date",
                                "displayDatePicker": true,
                                "format": "dd-MM-yyyy",
                                "class": "slds-input"
                            }
                        ], ["lightning:layoutItem",
                            {
                                "size": "12"
                            }
                        ], ["aura:html",
                            {
                                tag: "div",
                                HTMLAttributes: { "id": "Temp", "style": "width:100%; height:7px;" }
                            }
                        ], ["aura:html",
                            {
                                tag: "div",
                                HTMLAttributes: { "id": "Temp", "style": "width:100%; height:1px; background:Gainsboro;" }
                            }
                        ], ["lightning:layoutItem", { "size": "12" }]
                    ], function (components, status, errorMessage) {
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            components.forEach(function (item) {
                                body.push(item); //Adding the components to the body
                            });
                            component.set("v.body", body);
                        }
                        else if (status === "INCOMPLETE") { console.log("No response from server or client is offline.") }
                        else if (status === "ERROR") { console.log("Error: " + errorMessage); }
                    });
                }
            }
        }
    },

    previousTab: function (component, event, helper) {

        var activeTab = component.get("v.tabId");
        component.set("v.isFinished", false);

        if (activeTab == '2') {
            component.find("tabs").set("v.selectedTabId", '1');
            component.set("v.tabId", '1');
            component.set("v.displayConfigTab", false);
            component.set("v.body", []);
        }
    },

    finish: function (component, event, helper) {

        var splits = component.get("v.divisions");

        var datesMap = [];
        var amountsMap = [];

        for (var i = 0; i < splits; i++) {
            datesMap[i] = component.find("date" + i).get("v.value");
            amountsMap[i] = component.find("amount" + i).get("v.value");
            if (datesMap[i] == null || !datesMap[i]){ 
                $A.util.removeClass(component.find("date" + i), "removeHighlight");
				$A.util.addClass(component.find("date" + i), "highlightOnEmpty"); 
            }
            else { 
                $A.util.addClass(component.find("date" + i), "removeHighlight"); 
            }

            if (amountsMap[i] == null || !amountsMap[i]) { 
                $A.util.removeClass(component.find("amount" + i), "removeHighlight");
                $A.util.addClass(component.find("amount" + i), "highlightOnEmpty"); 
            }
            else { 
                $A.util.addClass(component.find("amount" + i), "removeHighlight");
            }
        }

        var action = component.get("c.createRecords");
        action.setParams({
            recordId: component.get("v.recordId"),
            dates: datesMap,
            amounts: amountsMap
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var redirect = response.getReturnValue();

                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": redirect,
                    "slideDevName": "detail"
                });
                navEvt.fire();
            }
            else if (state === "INCOMPLETE") { }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) { console.log("Error message: " + errors[0].message); }
                } else { console.log("Unknown error"); }
            }
        });
        $A.enqueueAction(action);
    },

    doInit: function (component, event, helper) {

        var action = component.get('c.currentOpportunityInfo');
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                component.set('v.controller', response.getReturnValue());
                var splitCurrentOpp = component.get("v.controller.splitOpportunity");
                if (splitCurrentOpp) {
                    component.set("v.isOpen", true);
                } else {
                    component.set("v.isOpen", false);
                }

                var currentOppIsAlreadySplit = component.get("v.controller.isAlreadySplit");
                if (currentOppIsAlreadySplit) {
                    component.set("v.alreadySplit", true);
                } else {
                    component.set("v.alreadySplit", false);
                }
            }
        });
        $A.enqueueAction(action);
    },

    showSpinner: function (component, event, helper) {//Displaying the spinner
        component.set("v.spinner", true);
    },

    hideSpinner: function (component, event, helper) {//Hiding the spinner
        component.set("v.spinner", false);
    }
})