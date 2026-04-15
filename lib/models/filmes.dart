class Filme {
  final int id;
  final String titulo;
  final String genero;
  final String duracao;
  final int faixaEtaria;

  Filme({
    required this.id,
    required this.titulo,
    required this.genero,
    required this.duracao,
    required this.faixaEtaria
  });

  /// Cria uma Filme a partir de um Map (vindo do JSON ou do banco)
  factory Filme.fromMap(Map<String, dynamic> map) {
    return Filme(
      id: map['id'] as int, // ← sem o ?
      titulo: map['titulo'] as String,
      genero: map['genero'] as String,
      duracao: map['duracao'] as String,
      faixaEtaria: map['faixaEtaria'] as int,
    );
  }

  /// Converte a Filme para Map (para salvar no banco ou retornar como JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'genero': genero,
      'duracao': duracao,
      'faixaEtaria': faixaEtaria,
    };
  }

  /// Converte para JSON (resposta da API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'genero': genero,
      'duracao': duracao,
      'faixaEtaria': faixaEtaria,
    };
  }
}
