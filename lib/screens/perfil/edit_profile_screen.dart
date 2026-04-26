import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nicknameController = TextEditingController();
  final bioController = TextEditingController();
  final picker = ImagePicker();

  final String cloudName = "dmp7mnhlu";
  final String uploadPreset = "encontros_upload";

  List<String> fotosExistentes = [];
  List<File> novasMidias = [];

  bool isLoading = true;
  double altura = 1.70;
  double distanciaBusca = 50.0;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Listas de Opções
  List<String> buscaSelecionados = [];
  List<String> prefsSelecionadas = [];
  List<String> bebidasSelecionadas = [];
  List<String> fumaSelecionados = [];

  final List<String> opcoesBusca = ["Namoro", "Amizade", "Algo casual", "Conversar"];
  final List<String> opcoesPreferencia = ["Homens", "Mulheres", "Ambos"];
  final List<String> opcoesBebida = ["Bebo socialmente", "Não bebo", "Bebo muito"];
  final List<String> opcoesFuma = ["Fumo", "Não fumo", "Ocasionalmente"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nicknameController.text = data['nikname'] ?? "";
        bioController.text = data['bio'] ?? "";
        altura = (data['altura'] ?? 1.70).toDouble();
        distanciaBusca = (data['distancia_maxima'] ?? 50.0).toDouble();
        fotosExistentes = List<String>.from(data['fotos'] ?? []);

        // Carregar as seleções do banco
        buscaSelecionados = List<String>.from(data['tipo_relacao'] ?? []);
        prefsSelecionadas = List<String>.from(data['preferencia'] ?? []);
        bebidasSelecionadas = List<String>.from(data['bebida'] ?? []);
        fumaSelecionados = List<String>.from(data['fuma'] ?? []);

        isLoading = false;
      });
    }
  }

  // Lógica de Mídia (Foto/Vídeo)
  Future<void> pickMidia() async {
    final String? tipo = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: Colors.pinkAccent),
            title: const Text("Adicionar Foto", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, "foto"),
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.pinkAccent),
            title: const Text("Adicionar Vídeo", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, "video"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (tipo == null) return;
    final XFile? picked = tipo == "foto"
        ? await picker.pickImage(source: ImageSource.gallery, imageQuality: 60)
        : await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => novasMidias.add(File(picked.path)));
    }
  }

  Future<String?> uploadToCloudinary(File file) async {
    bool eVideo = file.path.toLowerCase().endsWith(".mp4") || file.path.toLowerCase().endsWith(".mov");
    final String resourceType = eVideo ? "video" : "image";
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");
    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);
      return data["secure_url"];
    }
    return null;
  }

  Future<void> salvarAlteracoes() async {
    setState(() => isLoading = true);
    List<String> urlsFinais = List.from(fotosExistentes);

    for (var midia in novasMidias) {
      final url = await uploadToCloudinary(midia);
      if (url != null) urlsFinais.add(url);
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      "bio": bioController.text,
      "fotos": urlsFinais,
      "foto_principal": urlsFinais.isNotEmpty ? urlsFinais.first : null,
      "altura": altura,
      "distancia_maxima": distanciaBusca,
      "tipo_relacao": buscaSelecionados,
      "preferencia": prefsSelecionadas,
      "bebida": bebidasSelecionadas,
      "fuma": fumaSelecionados,
      "atualizado_em": FieldValue.serverTimestamp(),
    });

    setState(() => isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Minha Galeria", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // GRID DE MÍDIAS (Foto e Vídeo)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fotosExistentes.length + novasMidias.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                if (index == fotosExistentes.length + novasMidias.length) {
                  return GestureDetector(
                    onTap: pickMidia,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.add_circle_outline, color: Colors.pinkAccent, size: 35),
                    ),
                  );
                }

                if (index < fotosExistentes.length) {
                  String url = fotosExistentes[index];
                  bool eVideo = url.contains("/video/") || url.contains(".mp4");
                  return _buildMidiaItem(url: url, isVideo: eVideo, onDelete: () => setState(() => fotosExistentes.removeAt(index)));
                }

                int fileIndex = index - fotosExistentes.length;
                File file = novasMidias[fileIndex];
                bool eVideo = file.path.toLowerCase().endsWith(".mp4");
                return _buildMidiaItem(file: file, isVideo: eVideo, onDelete: () => setState(() => novasMidias.removeAt(fileIndex)), isNew: true);
              },
            ),

            const SizedBox(height: 25),
            _buildMultiSelectSection("O que você busca?", opcoesBusca, buscaSelecionados),
            _buildMultiSelectSection("Interesse em", opcoesPreferencia, prefsSelecionadas),
            _buildMultiSelectSection("Sobre bebida", opcoesBebida, bebidasSelecionadas),
            _buildMultiSelectSection("Sobre fumo", opcoesFuma, fumaSelecionados),

            const SizedBox(height: 20),
            _buildLabel("Raio de busca: ${distanciaBusca.toInt()} km"),
            Slider(
              value: distanciaBusca, min: 1, max: 300, divisions: 50,
              activeColor: Colors.orangeAccent,
              onChanged: (v) => setState(() => distanciaBusca = v),
            ),

            _buildLabel("Altura: ${altura.toStringAsFixed(2)}m"),
            Slider(
              value: altura, min: 1.40, max: 2.20,
              activeColor: Colors.pinkAccent,
              onChanged: (v) => setState(() => altura = v),
            ),

            _buildLabel("Sua Bio"),
            _buildTextField(bioController, "Escreva algo sobre você...", maxLines: 4),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isLoading ? null : salvarAlteracoes,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text("SALVAR ALTERAÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(t, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)));

  Widget _buildTextField(TextEditingController c, String h, {int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: c, maxLines: maxLines, readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white38 : Colors.white),
      decoration: InputDecoration(
        hintText: h, hintStyle: const TextStyle(color: Colors.white24),
        filled: true, fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildMultiSelectSection(String titulo, List<String> opcoes, List<String> selecionados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(titulo),
        Wrap(
          spacing: 8,
          children: opcoes.map((opcao) {
            final isSelected = selecionados.contains(opcao);
            return ChoiceChip(
              label: Text(opcao, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
              selected: isSelected,
              selectedColor: Colors.pinkAccent,
              backgroundColor: Colors.white10,
              onSelected: (selected) {
                setState(() {
                  selected ? selecionados.add(opcao) : selecionados.remove(opcao);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMidiaItem({String? url, File? file, required bool isVideo, required VoidCallback onDelete, bool isNew = false}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(15),
            border: isNew ? Border.all(color: Colors.pinkAccent, width: 2) : null,
            image: isVideo ? null : DecorationImage(
              image: isNew ? FileImage(file!) as ImageProvider : NetworkImage(url!),
              fit: BoxFit.cover,
            ),
          ),
          child: isVideo ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)) : null,
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: onDelete,
            child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 14)),
          ),
        ),
      ],
    );
  }
}