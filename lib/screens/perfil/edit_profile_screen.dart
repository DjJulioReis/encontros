import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/colors.dart';
import '../../core/location_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final profileNameController = TextEditingController(text: "Julio 🔥");
  final bioController = TextEditingController(
    text: "Curto sair, música e boas conexões 😏",
  );

  String selectedPreference = "Mulheres";

  void salvar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    // 🔥 PEGA LOCALIZAÇÃO GLOBAL
    final location = context.watch<LocationController>().city;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 📸 FOTO PERFIL
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    "https://i.pravatar.cc/300?img=5",
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.edit, size: 16),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 30),


            // ✏️ NOME PERFIL
            TextField(
              controller: profileNameController,
              decoration: const InputDecoration(
                labelText: "Nome do perfil",
              ),
            ),

            const SizedBox(height: 15),

            // 🔒 IDADE FIXA
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: "Idade",
                hintText: "25 (fixo)",
              ),
            ),

            const SizedBox(height: 15),

            // 🎯 PREFERÊNCIAS
            DropdownButtonFormField(
              value: selectedPreference,
              items: const [
                DropdownMenuItem(value: "Mulheres", child: Text("Mulheres")),
                DropdownMenuItem(value: "Homens", child: Text("Homens")),
                DropdownMenuItem(value: "Ambos", child: Text("Ambos")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPreference = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Preferências",
              ),
            ),

            const SizedBox(height: 15),

            // 📍 LOCALIZAÇÃO GLOBAL
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Localização"),
              subtitle: Text(location),
              trailing: const Icon(Icons.gps_fixed),
            ),

            const SizedBox(height: 15),

            // 🧾 BIO
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
              ),
            ),

            const SizedBox(height: 20),

            // 🔐 ALTERAR SENHA
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Alterar senha"),
              trailing: const Icon(Icons.lock),
              onTap: () {},
            ),

            const SizedBox(height: 20),

            // 📸 ENVIAR FOTOS
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Enviar fotos"),
              trailing: const Icon(Icons.image),
              onTap: () {},
            ),

            // 🎥 ENVIAR VÍDEO
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Enviar vídeo"),
              trailing: const Icon(Icons.videocam),
              onTap: () {},
            ),

            const SizedBox(height: 30),

            // 💾 SALVAR
            GestureDetector(
              onTap: salvar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryPink,
                      AppColors.primaryOrange,
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Salvar alterações",
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