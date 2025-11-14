import 'package:flutter/material.dart';

// --- FICAM NA PASTA application ---------------------------------------------
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

// --- Fica na pasta resources/shared -----------------------------------------

/// Gerencia a navegação global do aplicativo.
class AppCoordinator {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Widget startApp() {
    return goToLogin();
  }

  Widget goToLogin() {
    final login = LoginFactory.make(coordinator: this);
    
    // Se a chave do navegador já tiver um estado (ou seja, não é o primeiro build),
    // usamos pushReplacement para limpar a pilha (como em um Logout).
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => login ));
      // Retorna um Container temporário pois a navegação já foi solicitada
      return Container(); 
    }
    // Caso contrário, retorna a tela de login como o widget inicial
    return login;
  }
  
  void goToHome({required String name, required String address}) {
    final home = HomeFactory.make(name: name, address: address, coordinator: this);
    // Usa pushReplacement para que o usuário não possa voltar para o Login
    navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => home ));
  }
}

// --- Componente de Loading (resources/shared/loading_view.dart) ---
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white,),
    );
  }
}

extension LoadingPresentable on BuildContext {
  /// Mostra o indicador de carregamento em um diálogo.
  void showLoading() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false, // Impede o fechamento ao tocar fora
        child: Dialog(
          backgroundColor: Colors.black54,
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 80,
            child: const LoadingView(),
          ),
        ),
      ),
    );
  }

  /// Esconde o indicador de carregamento
  void hideLoading() {
    // Verifica se a tela atual é um diálogo para evitar pop indevido
    if (Navigator.of(this).canPop()) {
       Navigator.of(this).pop();
    }
  }
}
// -----------------------------------------------------------------------------

// --- Pasta Scenes/Home -------------------------------------------------------
class HomeFactory {
  static Widget make({required String name, required String address, required AppCoordinator coordinator}) {
    final viewModel = HomeViewModel(name: name, address: address, coordinator: coordinator);
    return HomeView(viewModel: viewModel);
  }
}

class HomeViewModel {
  final String name;
  final String address;
  final AppCoordinator coordinator;

  const HomeViewModel({required this.name, required this.address, required this.coordinator});

  String get displayName => name;
  String get displayAddress => address;
  
  void logOut() {
    // Lógica de logout (ex: limpar sessão) viria aqui.
    coordinator.goToLogin(); // Volta para a tela de Login
  }
}

class HomeView extends StatelessWidget {
  final HomeViewModel viewModel;
  const HomeView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false, // Impede o botão de voltar após o login
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Olá, **${viewModel.displayName}**!', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Seu endereço é: ${viewModel.displayAddress}', 
              style: const TextStyle(fontSize: 16)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: viewModel.logOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------


// --- Pasta Scenes/Login ------------------------------------------------------
class LoginFactory {
  static Widget make({required AppCoordinator coordinator}) {
    final service = LoginService();
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
    // Chamada do serviço (simulando requisição de rede)
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login MVVC', style: TextStyle(color: Colors.white)), backgroundColor: Colors.deepPurple),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // 1. Mostrar o Loading
            context.showLoading();
            
            await widget.viewModel.performLogin("user", "1234", onSuccess: (name, address) {
              // 2. Esconder o Loading e navegar para Home
              context.hideLoading();
              widget.viewModel.presentHome(name, address);
            });
            // Nota: Em um caso real, você teria um bloco try/catch aqui 
            // para garantir que o hideLoading seja chamado mesmo em caso de erro.
          },
          child: const Text('Fazer Login'),
        ),
      ),
    );
  }
}

class LoginService {
  Future <Map<String, dynamic>> fetchLogin({required String user, required String password}) async {
    // Simula um delay de rede de 3 segundos
    await Future.delayed(const Duration(seconds: 3));
    return {"name" : "Marcio Ferreira", "address" : "Rua Teotonio Segurado, 1234 - Plano diretor Sul"};
  }
}