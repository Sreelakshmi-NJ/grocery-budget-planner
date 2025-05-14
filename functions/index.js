const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const cors = require("cors")({origin: true});

/**
 * Generates cost-saving tips based on the monthly budget and
 * current spending.
 * @param {number} monthlyBudget - The monthly budget.
 * @param {number} currentSpent - The current spending amount.
 * @return {string[]} An array of cost-saving tips.
 */
function generateCostSavingTips(monthlyBudget, currentSpent) {
  if (monthlyBudget <= 0) {
    return ["Please provide a valid monthly budget greater than 0."];
  }

  const savingsRate = 1 - currentSpent / monthlyBudget;
  const tips = [];

  if (savingsRate < 0.2) {
    tips.push(
      "Your spending is high. Consider tracking your expenses daily and tightening your budget."
    );
  } else {
    tips.push(
      "Great job on savings! Keep monitoring your spending to maintain this trend."
    );
  }

  if (currentSpent > monthlyBudget * 0.8) {
    tips.push(
      "You're spending over 80% of your budget. Check for non-essential expenses."
    );
  } else {
    tips.push("Plan your grocery list in advance to maximize your savings.");
  }

  // Add a dynamic tip using a random choice.
  if (Math.random() > 0.5) {
    tips.push("Check local store flyers for discount offers this week.");
  } else {
    tips.push("Use digital coupons or loyalty apps to save even more.");
  }

  return tips;
}

exports.getCostSavingSuggestions = onRequest((req, res) => {
  cors(req, res, () => {
    try {
      // Validate request body
      const {monthlyBudget, currentSpent} = req.body;

      if (monthlyBudget === undefined || currentSpent === undefined) {
        res.status(400).json({
          status: "error",
          message: "Both 'monthlyBudget' and 'currentSpent' are required.",
        });
        return;
      }

      const mb = parseFloat(monthlyBudget);
      const cs = parseFloat(currentSpent);

      if (isNaN(mb) || isNaN(cs)) {
        res.status(400).json({
          status: "error",
          message: "'monthlyBudget' and 'currentSpent' must be valid numbers.",
        });
        return;
      }

      const tips = generateCostSavingTips(mb, cs);

      res.status(200).json({
        status: "success",
        tips: tips,
      });
    } catch (error) {
      logger.error("Error generating suggestions:", error);
      res.status(500).json({
        status: "error",
        message: "An error occurred while generating suggestions.",
      });
    }
  });
});
