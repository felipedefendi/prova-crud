import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImovelList(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('pt', 'BR'),
      ],
    );
  }
}

class ImovelList extends StatefulWidget {
  @override
  _ImovelListState createState() => _ImovelListState();
}

class _ImovelListState extends State<ImovelList> {
  List imoveis = [];
  TextEditingController descricaoController = TextEditingController();
  TextEditingController enderecoController = TextEditingController();
  TextEditingController dataCompraController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchImoveis();
  }

  fetchImoveis() async {
    var url = Uri.parse('http://localhost:8080/imoveis');
    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);

        if (decodedResponse != null && decodedResponse is List) {
          setState(() {
            imoveis = decodedResponse;
          });
        } else {
          setState(() {
            imoveis = [];
          });
        }
      } else {
        setState(() {
          imoveis = [];
        });
      }
    } catch (e) {
      setState(() {
        imoveis = [];
      });
    }
  }

  addImovel(String descricao, String endereco, String dataCompra) async {
    var url = Uri.parse('http://localhost:8080/imoveis');
    await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "descricao": descricao,
          "endereco": endereco,
          "dataCompra": dataCompra
        }));
    fetchImoveis();
  }

  updateImovel(
      int id, String descricao, String endereco, String dataCompra) async {
    var url = Uri.parse('http://localhost:8080/imoveis/$id');
    await http.put(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "descricao": descricao,
          "endereco": endereco,
          "dataCompra": dataCompra
        }));
    fetchImoveis();
  }

  deleteImovel(int id) async {
    var url = Uri.parse('http://localhost:8080/imoveis/$id');
    await http.delete(url);
    fetchImoveis();
  }

  addComodoToImovel(int imovelId, String nomeComodo) async {
    var url = Uri.parse('http://localhost:8080/comodos');
    await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nome": nomeComodo, "imovel_id": imovelId}));
    fetchImoveis();
  }

  showImovelDialog(
      {int? id,
      String? existingDescricao,
      String? existingEndereco,
      String? existingDataCompra}) {
    String descricao = existingDescricao ?? '';
    String endereco = existingEndereco ?? '';
    String dataCompra = existingDataCompra ?? '';
    TextEditingController dateController =
        TextEditingController(text: dataCompra);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Adicionar Imóvel' : 'Editar Imóvel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Descrição'),
                controller: TextEditingController(text: descricao),
                onChanged: (val) {
                  descricao = val;
                },
              ),
              TextField(
                decoration: InputDecoration(hintText: 'Endereço'),
                controller: TextEditingController(text: endereco),
                onChanged: (val) {
                  endereco = val;
                },
              ),
              TextField(
                decoration: InputDecoration(hintText: 'Data de Compra'),
                controller: dateController,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    locale: Locale('pt', 'BR'),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                    setState(() {
                      dateController.text = formattedDate;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (id == null) {
                  addImovel(descricao, endereco, dateController.text);
                } else {
                  updateImovel(id, descricao, endereco, dateController.text);
                }
                Navigator.of(context).pop();
              },
              child: Text(id == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  showComodoDialog(int imovelId) {
    String nomeComodo = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Adicionar Cômodo'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Nome do Cômodo'),
            onChanged: (val) {
              nomeComodo = val;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addComodoToImovel(imovelId, nomeComodo);
                Navigator.of(context).pop();
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Imóveis'),
      ),
      body: imoveis.isEmpty
          ? Center(child: Text('Nenhum imóvel disponível.'))
          : ListView.builder(
              itemCount: imoveis.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(imoveis[index]['descricao'] ??
                        'Descrição indisponível'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Endereço: ${imoveis[index]['endereco'] ?? 'Endereço indisponível'}'),
                        Text(
                            'Data de Compra: ${imoveis[index]['dataCompra'] ?? 'Data indisponível'}'),
                        Text('Cômodos:'),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (imoveis[index]['comodos'] ?? [])
                              .map<Widget>(
                                  (comodo) => Text(' - ${comodo['nome']}'))
                              .toList(),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showImovelDialog(
                              id: imoveis[index]['id'],
                              existingDescricao: imoveis[index]['descricao'],
                              existingEndereco: imoveis[index]['endereco'],
                              existingDataCompra: imoveis[index]['dataCompra'],
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteImovel(imoveis[index]['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () =>
                              showComodoDialog(imoveis[index]['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showImovelDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
