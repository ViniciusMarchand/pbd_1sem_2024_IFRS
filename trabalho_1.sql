DROP DATABASE IF EXISTS trabalho_1;

CREATE DATABASE trabalho_1;

\c trabalho_1;


CREATE TABLE pessoa(
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100),
    senha VARCHAR(100) NOT NULL,
    tipo CHAR(1),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE post(
    id SERIAL PRIMARY KEY,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    titulo VARCHAR(100) NOT NULL,
    texto TEXT,
    compartilhado BOOLEAN
);

CREATE TABLE pessoa_post(
    pessoa_id INTEGER REFERENCES pessoa(id),
    post_id INTEGER REFERENCES post(id),
    PRIMARY KEY(pessoa_id, post_id)
);

CREATE TABLE endereco(
    id SERIAL PRIMARY KEY,
    bairro VARCHAR(100),
    rua VARCHAR(100),
    nro VARCHAR(5),
    cep VARCHAR(10),
    pessoa_id INTEGER REFERENCES pessoa(id)
);



--2)

--a)
CREATE FUNCTION ehAutor(INTEGER) RETURNS BOOLEAN AS
$$
DECLARE
    ehAutor BOOLEAN;
    tipoPessoa char(1);
BEGIN
    SELECT tipo INTO tipoPessoa FROM pessoa WHERE id = $1;
    ehAutor := tipoPessoa = 'A';
    return ehAutor;
END;
$$ LANGUAGE 'plpgsql';

ALTER TABLE pessoa_post
ADD CONSTRAINT pessoa_id CHECK (ehAutor(pessoa_id));


--b)

CREATE FUNCTION verificaPost(INTEGER) RETURNS BOOLEAN AS
$$
DECLARE
    ehCompartilhado BOOLEAN;
    res BOOLEAN;
BEGIN
    SELECT compartilhado INTO ehCompartilhado FROM post WHERE id = $1;

    IF NOT ehCompartilhado THEN
        IF (SELECT count(*) FROM pessoa_post WHERE post_id = $1) = 1 THEN
            res := false;
        ELSE
            res:= true;
        END IF;
    ELSE
        res:= true;
    END IF;
    return res;
END;
$$ LANGUAGE 'plpgsql';

ALTER TABLE pessoa_post
ADD CONSTRAINT post_id CHECK (verificaPost(post_id));


--3)
CREATE OR REPLACE FUNCTION mostrarPessoas()
RETURNS TABLE(id INTEGER, nome VARCHAR(100), senha VARCHAR(100), tipo CHAR(1), email VARCHAR(100), endereco TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT pessoa.id, pessoa.nome, pessoa.senha, pessoa.tipo, pessoa.email, COALESCE(STRING_AGG(
endereco.bairro || ' ' || endereco.rua || ' ' || endereco.nro || ' ' || endereco.cep, ''
), 'AUTOR - NAO PODE TER ENDERECO CADASTRADO') AS endereco FROM pessoa LEFT JOIN endereco ON (pessoa.id = endereco.pessoa_id) GROUP BY pessoa.id ORDER BY id; 
END;
$$ LANGUAGE plpgsql;


--4)
CREATE FUNCTION ehLeitor(INTEGER) RETURNS BOOLEAN AS
$$
DECLARE
    ehAutor BOOLEAN;
    tipoPessoa char(1);
BEGIN
    SELECT tipo INTO tipoPessoa FROM pessoa WHERE id = $1;
    ehAutor := tipoPessoa = 'L';
    return ehAutor;
END;
$$ LANGUAGE 'plpgsql';


ALTER TABLE endereco
ADD CONSTRAINT pessoa_id CHECK (ehLeitor(pessoa_id));

--5)

CREATE OR REPLACE FUNCTION quantidadeAutoresPost()
RETURNS TABLE(id INTEGER, titulo VARCHAR(100), data_hora TIMESTAMP, qtde_autores bigint) AS $$
BEGIN
    RETURN QUERY
    SELECT post.id, post.titulo, post.data_hora, count(*) AS qtde_autores FROM post INNER JOIN pessoa_post ON (post.id = pessoa_post.post_id) GROUP BY post.id, post.titulo ORDER BY post.id;
END;
$$ LANGUAGE 'plpgsql';

--6)

CREATE OR REPLACE FUNCTION autoresPost()
RETURNS TABLE(id INTEGER, titulo VARCHAR(100), autores TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT post.id, post.titulo, STRING_AGG(pessoa.nome, ', ') AS autores FROM post LEFT JOIN pessoa_post ON (post.id = pessoa_post.post_id) INNER JOIN pessoa ON (pessoa_post.pessoa_id = pessoa.id) GROUP BY post.id ORDER BY post.id;END;
$$ LANGUAGE 'plpgsql';

--7)
CREATE OR REPLACE FUNCTION login(email_param VARCHAR(100), senha_param VARCHAR(100))
RETURNS BOOLEAN AS $$
DECLARE
    valido BOOLEAN;
    usuario RECORD;
BEGIN
    SELECT * INTO usuario FROM pessoa WHERE email = email_param;

    IF usuario.email IS NOT NULL AND usuario.senha = MD5(senha_param) THEN
        valido := true;
    ELSE
        valido := false;
    END IF;

    RETURN valido;
END;
$$ LANGUAGE plpgsql;


--INSERTS PARA TESTE

INSERT INTO pessoa (nome, senha, tipo, email) VALUES 
('Vinicius', MD5('Senh@123'), 'A', 'vinicius.marchand@gmail.com'),
('Victor', MD5('Senh@123'), 'A', 'victor.schmidt@gmail.com'),
('Artur', MD5('Senh@123'), 'L', 'Artur.Dalvit@gmail.com'),
('Poliana', MD5('Senh@123'), 'L', 'Poliana.Lette@gmail.com');

INSERT INTO post (titulo, texto, compartilhado) VALUES 
('Primeiro post', 'esse é meu primeiro post', true),
('Segundo post', 'esse é meu primeiro post', false);

INSERT INTO endereco(bairro, rua, nro, cep, pessoa_id) VALUES
('Salgado filho', 'Alcides Lima faria', '102', '96201490', 4),
('Centro', 'Primeiro de maio', '540','96201320', 3);

INSERT INTO pessoa_post (pessoa_id, post_id) VALUES 
(1, 1),
(2, 1),
(1, 2);



-- SELECT * FROM mostrarPessoas();

-- SELECT * FROM quantidadeAutoresPost();

-- SELECT * FROM autoresPost();

SELECT login('vinicius.marchan', 'Senh@12');
