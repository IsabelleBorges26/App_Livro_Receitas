
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.dart';
import 'style/colors.dart';

class Formulario extends StatefulWidget {
  final Map<String, dynamic>? receita;

  const Formulario({super.key, this.receita});

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final nomeController = TextEditingController();
  final ingredientesController = TextEditingController();
  final modoFazerController = TextEditingController();
  final imagemController = TextEditingController();
  final custoController = TextEditingController();

  String tipoSelecionado = 'DOCE';
  bool salvando = false;

  @override
  void initState() {
    super.initState();

    if (widget.receita != null) {
      nomeController.text = widget.receita!['nome']?.toString() ?? '';
      ingredientesController.text =
          widget.receita!['ingredientes']?.toString() ?? '';
      modoFazerController.text =
          widget.receita!['modoFazer']?.toString() ?? '';
      imagemController.text = widget.receita!['img']?.toString() ?? '';
      custoController.text =
          widget.receita!['custoAproximado']?.toString() ?? '';

      tipoSelecionado =
          widget.receita!['tipo']?.toString().toUpperCase() ?? 'DOCE';
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    ingredientesController.dispose();
    modoFazerController.dispose();
    imagemController.dispose();
    custoController.dispose();
    super.dispose();
  }

  Future<void> salvarReceita() async {
    if (nomeController.text.trim().isEmpty ||
        ingredientesController.text.trim().isEmpty ||
        modoFazerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o nome, os ingredientes e o modo de preparo.'),
        ),
      );
      return;
    }

    final custoTexto = custoController.text.trim().replaceAll(',', '.');
    final custo = custoTexto.isEmpty ? null : double.tryParse(custoTexto);

    if (custoTexto.isNotEmpty && custo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um custo válido.')),
      );
      return;
    }

    final dados = {
      'nome': nomeController.text.trim(),
      'tipo': tipoSelecionado,
      'ingredientes': ingredientesController.text.trim(),
      'modoFazer': modoFazerController.text.trim(),
      'img': imagemController.text.trim().isEmpty
          ? null
          : imagemController.text.trim(),
      'custoAproximado': custo,
    };

    setState(() {
      salvando = true;
    });

    try {
      http.Response resposta;

      if (widget.receita == null) {
        resposta = await http.post(
          Uri.parse(Api.getEndPoint('receitas')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dados),
        );
      } else {
        final id = widget.receita!['id'];

        resposta = await http.put(
          Uri.parse(Api.getEndPoint('receitas/$id')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dados),
        );
      }

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.receita == null
                  ? 'Receita adicionada!'
                  : 'Receita atualizada!',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível salvar a receita. Erro ${resposta.statusCode}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão com a API. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.receita != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar receita' : 'Adicionar receita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da receita',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo da receita',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'DOCE', child: Text('Doce')),
                DropdownMenuItem(value: 'SALGADA', child: Text('Salgada')),
                DropdownMenuItem(value: 'BEBIDA', child: Text('Bebida')),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    tipoSelecionado = valor;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: ingredientesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ingredientes',
                hintText: 'Digite os ingredientes e as quantidades',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: modoFazerController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Modo de preparo',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: imagemController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Link da imagem (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: custoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Custo aproximado (opcional)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: salvando ? null : salvarReceita,
                icon: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(salvando ? 'Salvando...' : 'Salvar receita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.c1,
                  foregroundColor: AppColors.c5,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
