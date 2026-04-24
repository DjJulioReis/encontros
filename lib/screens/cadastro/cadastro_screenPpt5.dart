import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../navigation/bottom_navigation.dart';

class CadastroStep5 extends StatefulWidget {
  final String userId;

  const CadastroStep5({super.key, required this.userId});

  @override
  State<CadastroStep5> createState() => _CadastroStep5State();
}

class _CadastroStep5State extends State<CadastroStep5> {

  final TextEditingController bioController = TextEditingController();

  List<File> imagens = [];
  bool loading = false;

  final picker = ImagePicker();

  // 🔥 CONFIG CLOUDINARY
  final String cloudName = "dmp7mnhlu";
  final String uploadPreset = "encontros_upload";

  // 📸 escolher imagem
  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (picked != null) {
      setState(() {
        imagens.add(File(picked.path));
      });
    }
  }

  // ❌ remover imagem
  void removeImage(int index) {
    setState(() {
      imagens.removeAt(index);
    });
  }

  // 🚀 UPLOAD CLOUDINARY
  Future<String?> uploadToCloudinary(File imageFile) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);
      return data["secure_url"];
    } else {
      return null;
    }
  }

  // 🔥 FINALIZAR CADASTRO
  Future<void> finishCadastro() async {
    if (imagens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adicione pelo menos 1 foto")),
      );
      return;
    }

    setState(() => loading = true);

    List<String> urls = [];

    // 🚀 faz upload de todas as imagens
    for (var img in imagens) {
      final url = await uploadToCloudinary(img);
      if (url != null) {
        urls.add(url);
      }
    }

    // 💾 salva no Firebase
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .update({
      "bio": bioController.text,
      "fotos": urls,
      "foto_principal": urls.first,

      "perfil_completo": true,
      "etapa": 999,

      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    // 🚀 entra no app
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔙 VOLTAR
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            const SizedBox(height: 20),

            const Text(
              "Seu perfil 🔥",
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text("Suas fotos",
                style: TextStyle(color: Colors.white70)),

            const SizedBox(height: 10),

            // 📸 LISTA DE FOTOS
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imagens.length + 1,
                itemBuilder: (context, index) {
                  if (index == imagens.length) {
                    return GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white10,
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: FileImage(imagens[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => removeImage(index),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            const Text("Bio",
                style: TextStyle(color: Colors.white70)),

            const SizedBox(height: 10),

            TextField(
              controller: bioController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Fale um pouco sobre você...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: loading ? null : finishCadastro,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D8D),
                      Color(0xFFFF6A00),
                    ],
                  ),
                ),
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Finalizar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}