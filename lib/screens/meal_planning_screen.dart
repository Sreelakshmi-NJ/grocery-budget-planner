import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealPlan {
  final String day;
  final Map<String, String> meals;  // mealType: recipeName
  final Map<String, List<String>> ingredients;  // mealType: [ingredients]

  MealPlan({
    required this.day,
    required this.meals,
    required this.ingredients,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'meals': meals,
      'ingredients': ingredients,
      'monthKey': DateFormat('yyyy-MM').format(DateTime.now()),
    };
  }
}

class Recipe {
  final String name;
  final String mealType;
  final List<String> ingredients;

  Recipe({
    required this.name,
    required this.mealType,
    required this.ingredients,
  });
}

class MealPlanningScreen extends StatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  State<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen> with SingleTickerProviderStateMixin {
  int numberOfDays = 7;
  List<MealPlan> mealPlan = [];
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> days = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday"
  ];

  final Map<String, List<Recipe>> recipes = {
    'breakfast': [
      Recipe(
        name: "Oatmeal with fruits",
        mealType: "breakfast",
        ingredients: ["oats", "milk", "fruits"],
      ),
      Recipe(
        name: "Egg sandwich",
        mealType: "breakfast",
        ingredients: ["eggs", "bread", "cheese"],
      ),
    ],
    'lunch': [
      Recipe(
        name: "Grilled chicken salad",
        mealType: "lunch",
        ingredients: ["chicken", "lettuce", "tomatoes", "cucumber"],
      ),
      Recipe(
        name: "Veggie wrap",
        mealType: "lunch",
        ingredients: ["tortilla", "lettuce", "tomatoes", "cucumber"],
      ),
    ],
    'dinner': [
      Recipe(
        name: "Steak with vegetables",
        mealType: "dinner",
        ingredients: ["steak", "potatoes", "carrots"],
      ),
      Recipe(
        name: "Stir-fried tofu",
        mealType: "dinner",
        ingredients: ["tofu", "rice", "vegetables"],
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMealPlan() async {
    if (_auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your meal plan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('mealPlans')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('monthKey', isEqualTo: selectedMonth)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          numberOfDays = snapshot.docs.length;
          mealPlan = snapshot.docs.map((doc) {
            final data = doc.data();
            return MealPlan(
              day: data['day'],
              meals: Map<String, String>.from(data['meals']),
              ingredients: Map<String, List<String>>.from(
                data['ingredients'].map((key, value) => MapEntry(key, List<String>.from(value))),
              ),
            );
          }).toList();
        });
      } else {
        await generateMealPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meal plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadMealPlan,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<List<String>> _getAvailablePantryItems() async {
    if (_auth.currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('pantry')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('monthKey', isEqualTo: selectedMonth)
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing pantry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> generateMealPlan() async {
    if (_auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to generate a meal plan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final availableIngredients = await _getAvailablePantryItems();
      List<MealPlan> newPlan = [];
      int daysToPlan = min(numberOfDays, days.length);
      Random random = Random();

      // Delete existing meal plan
      final existingPlans = await _firestore
          .collection('mealPlans')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .where('monthKey', isEqualTo: selectedMonth)
          .get();

      for (var doc in existingPlans.docs) {
        await doc.reference.delete();
      }

      for (int i = 0; i < daysToPlan; i++) {
        Map<String, String> dayMeals = {};
        Map<String, List<String>> dayIngredients = {};

        // For each meal type (breakfast, lunch, dinner)
        for (var mealType in ['breakfast', 'lunch', 'dinner']) {
          // Filter recipes based on available ingredients
          var possibleRecipes = recipes[mealType]!.where((recipe) {
            return recipe.ingredients.every((ingredient) =>
                availableIngredients.contains(ingredient.toLowerCase()));
          }).toList();

          if (possibleRecipes.isEmpty) {
            possibleRecipes = recipes[mealType]!;  // Use all recipes if none match pantry
          }

          // Select a random recipe
          var selectedRecipe = possibleRecipes[random.nextInt(possibleRecipes.length)];
          dayMeals[mealType] = selectedRecipe.name;
          dayIngredients[mealType] = selectedRecipe.ingredients;

          // Check missing ingredients
          var missingIngredients = selectedRecipe.ingredients
              .where((ingredient) => !availableIngredients.contains(ingredient.toLowerCase()))
              .toList();

          if (missingIngredients.isNotEmpty) {
            try {
              // Add missing ingredients to shopping list
              for (var ingredient in missingIngredients) {
                await _firestore.collection('shoppingList').add({
                  'userId': _auth.currentUser!.uid,
                  'name': ingredient,
                  'purchased': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding missing ingredients to shopping list: ${e.toString()}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        }

        // Create meal plan for the day
        final mealPlan = MealPlan(
          day: days[i],
          meals: dayMeals,
          ingredients: dayIngredients,
        );

        try {
          // Save to Firestore
          await _firestore.collection('mealPlans').add({
            ...mealPlan.toMap(),
            'userId': _auth.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          newPlan.add(mealPlan);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving meal plan: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        mealPlan = newPlan;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal plan generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating meal plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: generateMealPlan,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meal Planning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final missingItems = await _checkMissingIngredients();
              if (missingItems.isNotEmpty) {
                _showMissingIngredientsDialog(missingItems);
              }
            },
            icon: const Icon(Icons.inventory_2, color: Colors.white),
            label: const Text(
              'Check Ingredients',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[700]!,
              Colors.teal[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Plan Duration:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<int>(
                          value: numberOfDays,
                          underline: const SizedBox(),
                          items: List.generate(7, (index) {
                            int dayCount = index + 1;
                            return DropdownMenuItem(
                              value: dayCount,
                              child: Text(
                                "$dayCount ${dayCount == 1 ? 'Day' : 'Days'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                numberOfDays = value;
                              });
                              generateMealPlan();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('mealPlans')
                      .where('userId', isEqualTo: _auth.currentUser?.uid)
                      .where('monthKey', isEqualTo: selectedMonth)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      );
                    }

                    final mealPlans = snapshot.data!.docs;
                    if (mealPlans.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.teal[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No meal plan available',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate a meal plan to get started',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: generateMealPlan,
                              icon: const Icon(Icons.add),
                              label: const Text('Generate Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: mealPlans.length,
                      itemBuilder: (context, index) {
                        final data = mealPlans[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Dismissible(
                              key: Key(mealPlans[index].id),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) async {
                                await _firestore
                                    .collection('mealPlans')
                                    .doc(mealPlans[index].id)
                                    .delete();
                              },
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  onExpansionChanged: (expanded) {
                                    if (expanded) {
                                      _animationController.forward();
                                    } else {
                                      _animationController.reverse();
                                    }
                                  },
                                  title: Text(
                                    data['day'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  children: [
                                    FadeTransition(
                                      opacity: _animation,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            _buildMealTile(
                                              'Breakfast',
                                              data['meals']['breakfast'],
                                              Icons.breakfast_dining,
                                            ),
                                            const Divider(),
                                            _buildMealTile(
                                              'Lunch',
                                              data['meals']['lunch'],
                                              Icons.lunch_dining,
                                            ),
                                            const Divider(),
                                            _buildMealTile(
                                              'Dinner',
                                              data['meals']['dinner'],
                                              Icons.dinner_dining,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: generateMealPlan,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate New Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTile(String mealType, String mealName, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        mealType,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        mealName,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Future<List<String>> _checkMissingIngredients() async {
    final availableIngredients = await _getAvailablePantryItems();
    Set<String> missingIngredients = {};

    for (var plan in mealPlan) {
      plan.ingredients.forEach((mealType, ingredients) {
        for (var ingredient in ingredients) {
          if (!availableIngredients.contains(ingredient.toLowerCase())) {
            missingIngredients.add(ingredient);
          }
        }
      });
    }

    return missingIngredients.toList();
  }

  void _showMissingIngredientsDialog(List<String> missingItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Missing Ingredients'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following ingredients are missing from your pantry:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...missingItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              )),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              for (var item in missingItems) {
                await _firestore.collection('shoppingList').add({
                  'userId': _auth.currentUser!.uid,
                  'name': item,
                  'purchased': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Items added to shopping list'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Shopping List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
