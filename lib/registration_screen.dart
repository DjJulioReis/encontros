import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // ADICIONADO: Para o GPS

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOTPSent = false;
  String _verificationId = "";

  // --- NOVAS VARIÁVEIS (Resolvendo os erros de Undefined) ---
  String? _generoSelecionado;
  List<String> _interessesSelecionados = [];
  double _altura = 1.70;

  final _dateMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  int _calculateAge(String dateStr) {
    try {
      DateTime birthDate = DateFormat('dd/MM/yyyy').parse(dateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  void _verifyPhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      if (_calculateAge(_dateController.text) < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você deve ter pelo menos 18 anos.")),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String fullPhone = "+55${_phoneMask.getUnmaskedText()}";

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _saveUserToFirestore();
        },
        verificationFailed: (FirebaseAuthException e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro: ${e.message}")),
          );
        },
        codeSent: (String verId, int? resendToken) {
          Navigator.pop(context);
          setState(() {
            _verificationId = verId;
            _isOTPSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    }
  }

  void _confirmCodeAndRegister() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _saveUserToFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código inválido!")),
      );
    }
  }

  Future<void> _saveUserToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Pegando Localização Real
      Position position = await Geolocator.getCurrentPosition();

      DateTime dateObj = DateFormat('dd/MM/yyyy').parse(_dateController.text);
      String formattedBirthDate = DateFormat('yyyy-MM-dd').format(dateObj);

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
        'uid': user.uid,
        'nome_completo': _nameController.text.trim(),
        'telefone': user.phoneNumber,
        'data_nascimento': formattedBirthDate,
        'is_adult': _calculateAge(_dateController.text) >= 18,
        'nome_usuario': _nameController.text.split(' ')[0],
        'genero': _generoSelecionado ?? "Não informado", // Evita erro de nulo
        'procura_por': _interessesSelecionados,
        'altura': _altura,
        'lat': position.latitude,
        'lng': position.longitude,
        'perfil_completo': true,
        'criado_em': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/radar');
      }
    } catch (e) {
      print("Erro ao salvar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Crie sua conta", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Insira seu nome" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneMask],
                decoration: const InputDecoration(labelText: "Telefone", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                inputFormatters: [_dateMask],
                decoration: const InputDecoration(labelText: "Data de Nascimento (DD/MM/AAAA)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),

              // --- SELETORES DE GÊNERO (Opcional colocar aqui ou em outra tela) ---
              const SizedBox(height: 20),
              const Text("Identidade de Gênero:"),
              DropdownButton<String>(
                value: _generoSelecionado,
                hint: const Text("Selecione"),
                isExpanded: true,
                items: ["Homem", "Mulher", "Homem Trans", "Mulher Trans", "Casal"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _generoSelecionado = val),
              ),

              const SizedBox(height: 32),
              if (!_isOTPSent)
                ElevatedButton(
                  onPressed: _verifyPhoneNumber,
                  child: const Text("ENVIAR CÓDIGO SMS"),
                )
              else ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(labelText: "Código SMS"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _confirmCodeAndRegister,
                  child: const Text("CONFIRMAR E ENTRAR"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}