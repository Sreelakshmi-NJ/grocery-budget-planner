// Remove the "library;" line if it is not needed.
import 'package:firebase_data_connect/firebase_data_connect.dart';

class DefaultConnector {
  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'grocery_budget_planner',
  );

  DefaultConnector({required this.dataConnect});

  static DefaultConnector get instance {
    return DefaultConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,
        // Removed the sdkType parameter since it's not defined.
      ),
    );
  }

  final FirebaseDataConnect dataConnect;
}
