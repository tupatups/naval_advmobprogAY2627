# Christopher Naval
## INF231
### CTADMOBL Advanced Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web Transactions.c

## Lab Activity Instance

- Lab Activity 1: setState⁠ is for local, single-screen state like yung counter example. When the counter changes, the setState tells Flutter to refresh that specific screen. Provider is for shared, app-wide state like yung theme switcher. It keeps the theme data in a separate class outside the UI and makes it available to the entire app. When you toggle the switch, Provider notifies every screen listening to the theme so they all update together seamlessly.


- Lab Activity 2: Model, Service, Screen: The model defines what a product's data looks like. The service fetches that data from the API and organizes it using the model. The screen just displays it, showing loading, error, or the final product list. Each piece has one job, making the app easier to manage. New Design Pattern: This activity uses a pattern where shared settings (like dark mode) are broadcast to the whole app. When it changes, every part that needs it updates automatically, no manual passing between screens needed.
