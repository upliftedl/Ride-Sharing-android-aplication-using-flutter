import 'package:flutter/material.dart';
import 'login_screen.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Find Rides Anywhere",
      "description":
          "Discover rides to your destination with ease. Whether you're commuting to work or heading out for fun, we've got you covered."
    },
    {
      "title": "Share Your Ride",
      "description":
          "Going somewhere? Share your ride with others and save on travel costs. It's eco-friendly and economical!"
    },
    {
      "title": "Safe and Reliable",
      "description":
          "Travel with confidence. All drivers and riders are verified to ensure a safe and comfortable journey."
    },
    {
      "title": "Real-Time Tracking",
      "description":
          "Track your ride in real-time. Know exactly when your driver will arrive and follow the route to your destination."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      "assets/onboarding/ride1.png"), // Background image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Semi-transparent Overlay
            Container(
              color: Colors.black.withOpacity(0.5), // Adjust opacity here
            ),
            // Onboarding Content
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        title: onboardingData[index]["title"]!,
                        description: onboardingData[index]["description"]!,
                      );
                    },
                  ),
                ),
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => buildDot(index: index),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons (Skip & Next / Get Started)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _pageController.jumpToPage(onboardingData.length - 1);
                        },
                        child: const Text(
                          "Skip",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == onboardingData.length - 1) {
                            // Navigate to HomeScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == onboardingData.length - 1
                              ? "Get Started"
                              : "Next",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;

  const OnboardingPage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bike_outlined, // Example icon
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
