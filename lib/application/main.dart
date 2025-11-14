import 'package:flutter/material.dart';

//FICAM NA PASTA application
void main() {
  final coordinator = AppCoordinator();
  runApp(Application(coordinator: coordinator));
}

class Application extends StatelessWidget {
  final AppCoordinator coordinator;
  const Application({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "MVVC Sample",
                       navigatorKey: coordinator.navigatorKey,
                       theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
                       home: coordinator.startApp());
  }
}

//Fica na pasta resources/shared
class AppCoordinator {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Widget startApp() {
    return goToLogin();
  }

  Widget goToLogin() {
    return LoginFactory.make(coordinator: this);
  }
  
  void goToHome({required String name, required String address}) {
    final home = HomeFactory.make(name: name, address: address, coordinator: this);
    navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => home ));
  }
}

class HomeFactory {
  static Widget make({required String name, required String address, required AppCoordinator coordinator}) {
    return Container();
  }
}
//Pasta Scenes/Login
class LoginFactory {
  static Widget make({required AppCoordinator coordinator}) {
    final service  = LoginService();
    final viewModel = LoginViewModel(service: service, coordinator: coordinator);
    return LoginView(viewModel: viewModel);
  }
}

class LoginViewModel {
  final LoginService service;
  final AppCoordinator coordinator;
  const LoginViewModel({required this.service, required this.coordinator});
  
  AppCoordinator get appCoordinator => coordinator;
  
  Future<void> performLogin(String user, 
                            String password, 
                            { required void Function(String name, String address) onSuccess, }) async {
    final response = await service.fetchLogin(user: user, password: password);
    
    final name = response["name"] as String? ?? "";
    final address = response["address"] as String? ?? "";
    
    onSuccess(name, address);
  }
  
  void presentHome(String name,
                   String address) {
    coordinator.goToHome(name: name, address: address);
  }
}

class LoginView extends StatefulWidget {
  final LoginViewModel viewModel;
  const LoginView({super.key, required this.viewModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    return Center(child:
    ElevatedButton(onPressed: () async {
      await widget.viewModel.performLogin("user", "1234", onSuccess: (name, address) {
        widget.viewModel.presentHome(name, address);
      });
    },
      child: const Text('Login'),),);
  }
}

class LoginService {
  Future <Map<String, dynamic>> fetchLogin({required String user, required String password}) async {
    await Future.delayed(const Duration(seconds: 3));
    return  {"name" : "Marcio Ferreira", "address" : "Rua Teotonio Segurado, 1234 - Plano diretor Sul"};
  }
}


















