Introduction: This is a simple Shopping List App I created via Claude 4 (at https://claude.ai/) to run on my iPhone 8 without any prior experience with Xcode nor SwiftUI.

Motivation: The motivation for creating this App was to eliminate using paper shopping lists. The paper shopping lists were a pain. The scribbled items were difficult to read, they would get lost, old shopping lists that weren't disposed after shopping were unintentionally reused, items wouldn't get crossed off, etc.

The Prompt: This was the prompt I used to have Claude Sonnet 4 generate the code and directions for me to follow to create this simple Shopping List App:

I want to build a Shopping List app for personal use only that supports the following modes: -Pre-Shopping mode: occurs prior to shopping with iphone connected to Wifi -CRUD support shall be provided for Shopping Lists via a persistent store.. New Shopping Lists can be created by using a previous Shopping List as a Template (ie, cloning) or created from scratch.

-Shopping List Usage mode: during shopping on iphone offline in store
-items in a Selected Shopping List can be viewed during shopping. -each item in the Shopping List shall have checkboxes that can be toggled to indicate whether an item was placed in the cart. -items can be added, deleted or edited while shopping.

-Post-Shopping mode: occurs after shopping with iphone connected to Wifi -items can be added, deleted or edited while shopping. -the shopping list can be saved.

-Maintenance mode: -CRUD support shall be provided for Shopping Lists via a persistent store.

-Shopping Lists shall be identified by the following attributes: -Store Name -Date Shopping is to be used.
-Each item in the Shopping List shall contain the following attributes; -item name -item purchased (ie, placed in cart while shopping) -item description -Things to consider: -The app will Not be placed on the Apple Store. The app will be for personal use only. -Xcode 16.4 will be used for development and testing. -security -No network connectivity while shopping.

