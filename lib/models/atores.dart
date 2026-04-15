class Ator {
  final int id;
  String nome;
  String personagem;
  int idade;
  int filmeId;

  Ator({
    required this.id,
    required this.nome,
    required this.personagem,
    required this.idade,
    required this.filmeId,
  }); // ← ponto e vírgula aqui

  factory Ator.fromMap(Map<String, dynamic> map) { // ← Ator, não Filme
    return Ator(
      id: map['id'] as int,
      nome: map['nome'] as String,
      idade: map['idade'] as int, // ← int, não String
      personagem: map['personagem'] as String,
      filmeId: map['filmeId'] as int,
    );
  }
  
  Map<String, dynamic> toMap()  {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'personagem': personagem,
      'filmeId': filmeId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'personagem': personagem,
      'filmeId': filmeId,
    };
  }
}

