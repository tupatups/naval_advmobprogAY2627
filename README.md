# Christopher Naval
## INF231
### CTADMOBL Advanced Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web Transactions.c

## Lab Activity Instance

- Lab Activity 1: setState⁠ is for local, single-screen state like yung counter example. When the counter changes, the setState tells Flutter to refresh that specific screen. Provider is for shared, app-wide state like yung theme switcher. It keeps the theme data in a separate class outside the UI and makes it available to the entire app. When you toggle the switch, Provider notifies every screen listening to the theme so they all update together seamlessly.


- Lab Activity 2: Model, Service, Screen: The model defines what a product's data looks like. The service fetches that data from the API and organizes it using the model. The screen just displays it, showing loading, error, or the final product list. Each piece has one job, making the app easier to manage. New Design Pattern: This activity uses a pattern where shared settings (like dark mode) are broadcast to the whole app. When it changes, every part that needs it updates automatically, no manual passing between screens needed.

- Lab Activity 3: In this activity, I utilized a service-oriented design pattern where my cart model, services, and screen interact to efficiently separate the visual rendering from the backend API logic. My CartScreen acts as the view, using a StatefulWidget to manage the local state while calling CartService().getUserCart(widget.userId) to populate the screen with a list of CartProduct models. To implement the getById approach from the cart endpoint, I relied on the navigateToDetail(int productId) method. When a specific cart item is tapped, this method displays a loading indicator and triggers ProductService().getProductById(productId) to fetch the complete product data from the API. Once my service successfully returns this data, the application uses Navigator.push to route to detail_screen.dart, passing the retrieved fullProduct object along to render the specific details of that item.