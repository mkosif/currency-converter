# Currency Converter App

CurrencyConverter is a fully functional wearable watch application including currency convert functionality built for **HarmonyOS NEXT wearable devices**,
developed using **ArkTS**.
This demo showcases a simple yet effective smartwatch app that allows users to convert currencies instantly with a minimal and intuitive interface. The app consists of two main screens:

# Preview
<div>
  <img src="./Screenshots/image1.png" width="25%"/>
  <img src="./Screenshots/image2.png" width="25%"/>
  <img src="./Screenshots/image3.png" width="25%"/>
</div>

# Use Cases

Currency Converter Clock App is designed to make daily currency checking and conversion more seamless and accessible, especially on-the-go. The following are the application's featured use cases:

- Real-Time Currency Conversion: Users can quickly convert between major currencies such as USD, EUR, GBP, TRY, and more while traveling, shopping, or budgeting.
- Instant Access via Watch Interface: With its intuitive and minimal interface, users can perform conversions directly from the smartwatch without needing to pull out a phone.
- Always Up-to-Date Rates: The app fetches the latest exchange rates via internet connection and presents them in a clean format optimized for quick readability.
- One-Tap Currency Selection: Users can easily switch base and target currencies with a single tap, making the app practical for frequently changing currency pairs.
- Converter Page: On this screen, users can select a base currency and convert it to another with real-time results. It provides instant conversion feedback with a user-friendly layout optimized for watch screens.
- Exchange Rate Page: This screen displays a list of the most recent exchange rates fetched from an online service. Users can browse through the currencies and monitor current trends at a glance.
- Selecting currency types from selection page
- 14 Currency Support

# Tech Stack

**@kit.ArkGraphics2D** :
- common2D : Used to define RGBA color values for custom color creation.
- drawing : Used to create a ColorFilter with blending modes to apply visual effects on images/icons.

**@kit.RemoteCommunicationKit** :
- rcp : Used to fetch live exchange rates over HTTPS from the Frankfurter API.

# Networking

- Provider: [Frankfurter](https://www.frankfurter.app/) — free, public, no API key required.
- Endpoint: `https://api.frankfurter.app/latest?from=USD`. The base currency is fixed to USD; per-currency conversions are computed locally as `target.rate / base.rate`.
- Permission: requires `ohos.permission.INTERNET` (declared in `entry/src/main/module.json5`).
- Fallback behaviour: the app ships with hard-coded fallback rates for every supported currency. If the network call fails or the response is malformed (e.g. wrong base, missing keys, non-numeric values), the previous rates are kept; the UI shows an "Update failed" status and stale rates remain usable offline.
- The Update chip on the Exchange page shows `Update` / `Updating...` / `Just updated` / `Update failed`. While a request is in flight, repeat taps are ignored; if the user navigates away before it returns, the stale callback is discarded.

# Supported Currencies

USD, EUR, GBP, JPY, TRY, CAD, CHF, CNY, INR, BRL, MXN, ZAR, KRW, RUB (14 total).

# Directory Structure

```
entry/src/main/ets/
│
├── viewmodel/
│ ├── CurrencyData.ets // CurrencyData model
│ │── CurrencyViewModel.ets // Currency Data Source and Calculations
│
├── pages/
│ ├── ExchangePage.ets // Main Page of application
│ │── NavigationRouter.ets // Navigation Container
│ │── SelectCurrencyPage.ets // Currency List Page for selecting
│ └── SplashPage.ets // Welcome Page of application
│
├── view/
│ ├── BaseCurrencyRow.ets // Currency component requested to be converted
│ │── CurrencyItem.ets // Core Component of BaseCurrencyRow and TargetCurrencyRow
│ │── SearchBar.ets // SearchBar component
│ └── TargetCurrencyRow.ets // Currency component requested to be viewed as output
│
├─ resources/
│ └── media/ // Flag sprites & meta icons
│
└── module.json5 // Metadata and device compatibility
```

# Constraints and Restrictions

## Supported Device

* Huawei Watch 5
* DevEco Studio Simulator

## Restrictions

Known Issue:
Keyboard is not working on previewer. Test the amount-input flow on the simulator or a physical Watch 5 instead.

# Build & Test

The project uses the standard HarmonyOS toolchain. Open the project in DevEco Studio and either run the configurations from the IDE or invoke `hvigorw` from the command line:

- Build a debug HAP: `hvigorw assembleHap --mode debug`
- Run local unit tests (`entry/src/test`): `hvigorw test`
- Run on-device / simulator instrumentation tests (`entry/src/ohosTest`): `hvigorw ohosTest`

Local unit tests cover `CurrencyViewModel` pure logic (input validation, decimal formatting, search, code lookup, and Frankfurter response mapping including fallback preservation).

# LICENSE

Currency Converter is distributed under the terms of the MIT License.
See the [LICENSE](LICENSE) for more information.
