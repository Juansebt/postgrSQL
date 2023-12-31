PGDMP                  
    {            Clinica    16.0    16.0 M    A           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            B           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            C           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            D           1262    16397    Clinica    DATABASE        CREATE DATABASE "Clinica" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Spanish_Colombia.1252';
    DROP DATABASE "Clinica";
                postgres    false                        2615    16398    clinica    SCHEMA        CREATE SCHEMA clinica;
    DROP SCHEMA clinica;
                postgres    false            E           0    0    SCHEMA clinica    ACL     �   GRANT USAGE ON SCHEMA clinica TO dba;
GRANT USAGE ON SCHEMA clinica TO jefe_especialista;
GRANT USAGE ON SCHEMA clinica TO especialista;
GRANT USAGE ON SCHEMA clinica TO recepcionista;
                   postgres    false    5            l           1247    16406    id_cita    DOMAIN     �   CREATE DOMAIN clinica.id_cita AS character(7) NOT NULL
	CONSTRAINT id_cita_check CHECK ((VALUE ~ '^[CM]{2}[-]{1}\d{4}$'::text));
    DROP DOMAIN clinica.id_cita;
       clinica          postgres    false    5            h           1247    16403    id_meespecialista    DOMAIN     �   CREATE DOMAIN clinica.id_meespecialista AS character(7) NOT NULL
	CONSTRAINT id_meespecialista_check CHECK ((VALUE ~ '^[ME]{2}[-]{1}\d{4}$'::text));
 '   DROP DOMAIN clinica.id_meespecialista;
       clinica          postgres    false    5            d           1247    16400    id_paciente    DOMAIN     �   CREATE DOMAIN clinica.id_paciente AS character(6) NOT NULL
	CONSTRAINT id_paciente_check CHECK ((VALUE ~ '^[P]{1}[-]{1}\d{4}$'::text));
 !   DROP DOMAIN clinica.id_paciente;
       clinica          postgres    false    5            �            1255    16559    actualizadopaciente()    FUNCTION     �  CREATE FUNCTION clinica.actualizadopaciente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	usuario VARCHAR(20) := (SELECT current_user);
	fechaActual TIMESTAMP := (SELECT LEFT(CAST (CURRENT_TIMESTAMP AS CHAR(30)), 19 ));
BEGIN
	INSERT INTO CLINICA.DATOS_PACIENTES_PERSONAL 
	(tipoMovimiento, idPaciente, nombrePaciente, apellidoPaciente, usuario, fecha) VALUES
	('ACTUALIZACIÓN', OLD.pk_idPaciente, OLD.nombre ,OLD.apellido, usuario, fechaActual);
RETURN NEW;
END
$$;
 -   DROP FUNCTION clinica.actualizadopaciente();
       clinica          postgres    false    5            �            1255    16557    borradopaciente()    FUNCTION     �  CREATE FUNCTION clinica.borradopaciente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	usuario VARCHAR(20) := (SELECT CURRENT_USER);
	fechaActual TIMESTAMP := (SELECT LEFT(CAST (CURRENT_TIMESTAMP AS CHAR(30)), 19));
BEGIN
	INSERT INTO CLINICA.DATOS_PACIENTES_PERSONAL 
	(tipoMovimiento, idPaciente, nombrePaciente, apellidoPaciente, usuario, fecha) VALUES
	('BORRADO', OLD.pk_idPaciente, OLD.nombre ,OLD.apellido, usuario, fechaActual);
RETURN NEW;
END
$$;
 )   DROP FUNCTION clinica.borradopaciente();
       clinica          postgres    false    5            �            1255    16545    cancelarcita(clinica.id_cita) 	   PROCEDURE     G  CREATE PROCEDURE clinica.cancelarcita(IN idcita clinica.id_cita)
    LANGUAGE plpgsql
    AS $$
DECLARE
	status CHAR(10) := (SELECT status FROM CLINICA.AGENDAR_CITA WHERE fk_idCita = idCita);
BEGIN

	IF NOT EXISTS (SELECT pk_idCita FROM CLINICA.CITA WHERE pk_idCita = idCita) THEN
		RAISE NOTICE 'EL ID DE LA CITA NO EXISTE EN LA BASE DE DATOS';
	ELSEIF status = 'REALIZADO' THEN
		RAISE NOTICE 'LA CITA YA HA SIDO REALIZADA';
	ELSE
		UPDATE CLINICA.AGENDAR_CITA SET status = 'CANCELADA' WHERE fk_idCita = idCita;
		
		RAISE NOTICE 'CITA CANCELADA CORRECTAMENTE';
	END IF;

END; $$;
 @   DROP PROCEDURE clinica.cancelarcita(IN idcita clinica.id_cita);
       clinica          postgres    false    876    5            �            1255    16523    holamundo()    FUNCTION     �   CREATE FUNCTION clinica.holamundo() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE 
	mensaje VARCHAR(20) := 'HOLA MUNDO';
BEGIN
	RETURN mensaje;
END;
$$;
 #   DROP FUNCTION clinica.holamundo();
       clinica          postgres    false    5            �            1255    16541 �   insertarcitaagendarcita(clinica.id_paciente, clinica.id_meespecialista, character varying, date, time without time zone, character varying) 	   PROCEDURE     �  CREATE PROCEDURE clinica.insertarcitaagendarcita(IN idpaciente clinica.id_paciente, IN idespecialista clinica.id_meespecialista, IN consultorio character varying, IN fechacita date, IN horacita time without time zone, IN observaciones character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
	idCita CHAR(7);
	idCitaAux CHAR(4);
	fechaActual DATE := (SELECT CURRENT_DATE);
	horaActual TIME := (SELECT CURRENT_TIME);
	turno VARCHAR(10);
BEGIN

	IF NOT EXISTS (SELECT pk_idCita FROM CLINICA.CITA WHERE pk_idCita = 'CM-0001') THEN
		idCita = 'CM-0001';
	ELSE
		idCita := (SELECT pk_idCita FROM CLINICA.CITA ORDER BY pk_idCita DESC LIMIT 1);
		idCitaAux := (SELECT SUBSTRING(idCita, 4, 7));
		idCitaAux := CAST(idCitaAux AS INT)+1;
		
		IF idCitaAux < '9' THEN
			idCita = 'CM-00' || idCitaAux;
		ELSEIF idCitaAux BETWEEN '10' AND '99' THEN
			idCita = 'CM-0' || idCitaAux;
		ELSEIF idCitaAux BETWEEN '100' AND '999' THEN
			idCita = 'CM-' || idCitaAux;
		END IF;
	END IF;
	
	IF horaCita >= '12:00' THEN
		turno = 'VESPERTINO';
	ELSE
		turno = 'MATUTINO';
	END IF;
	
	IF fechaCita < fechaActual THEN
		RAISE NOTICE 'NO SE PUEDE HACER CITAS EN FECHAS ANTERIORES - CITA NO INGRESADA';
	ELSE
		INSERT INTO CLINICA.CITA VALUES (idCita, idPaciente, fechaActual, horaActual);
		
		INSERT INTO CLINICA.AGENDAR_CITA VALUES 
		(idCita, idEspecialista, consultorio, fechaCita, horaCita, turno, 'ESPERA', observaciones);
		
		RAISE NOTICE 'CITA INGRESADA CORRECTAMENTE';
	END IF;

END; $$;
 �   DROP PROCEDURE clinica.insertarcitaagendarcita(IN idpaciente clinica.id_paciente, IN idespecialista clinica.id_meespecialista, IN consultorio character varying, IN fechacita date, IN horacita time without time zone, IN observaciones character varying);
       clinica          postgres    false    868    872    5            �            1255    16543 �   insertardiagnostico(clinica.id_meespecialista, clinica.id_paciente, character, character, character, character, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE clinica.insertardiagnostico(IN idespecialista clinica.id_meespecialista, IN idpaciente clinica.id_paciente, IN edad character, IN peso character, IN altura character, IN presionarterial character, IN diagnostico character varying, IN recetario character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
	imc REAL;
	pesoNum INT;
	alturaNum REAL;
	nivelPeso CHAR(10);
	fechaCreacion TIMESTAMP := (SELECT LEFT(CAST (CURRENT_TIMESTAMP AS CHAR(30)),19));
BEGIN

	pesoNum := peso;
	alturaNum := altura;
	imc := pesoNum / (alturaNum*alturaNum);
	imc := CAST(imc AS CHAR(5));
	
	IF imc < '18.5' THEN
		nivelPeso = 'BAJO';
	ELSEIF imc BETWEEN '18.5' AND '24.9' THEN
		nivelPeso = 'NORMAL';
	ELSEIF imc BETWEEN '25.0' AND '29.9' THEN
		nivelPeso = 'SOBREPESO';
	ELSE
		nivelPeso = 'OBESIDAD';
	END IF;
	
	INSERT INTO CLINICA.EXPEDIENTE_DIAGNOSTICO 
	(fk_idEspecialista, fk_idPaciente, edad, peso, altura, imc, nivelPeso, presionArterial,
	diagnostico, recetario, fechaCreacion)
	VALUES (idEspecialista, idPaciente, edad, peso, altura, imc, nivelPeso, presionArterial,
		   diagnostico, recetario, fechaCreacion);
		   
	RAISE NOTICE 'EXPEDIENTE DIAGNOSTICO INGRESADO CORRECTAMENTE';

END; $$;
   DROP PROCEDURE clinica.insertardiagnostico(IN idespecialista clinica.id_meespecialista, IN idpaciente clinica.id_paciente, IN edad character, IN peso character, IN altura character, IN presionarterial character, IN diagnostico character varying, IN recetario character varying);
       clinica          postgres    false    868    872    5            �            1255    16540 ^   insertarespecialista(character varying, character varying, character, date, character varying) 	   PROCEDURE     �  CREATE PROCEDURE clinica.insertarespecialista(IN nombre character varying, IN apellido character varying, IN sexo character, IN fechanacimiento date, IN especialidad character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	idEspecialista CHAR(7);
	idEspecialistaAux CHAR(4);
BEGIN 

	IF NOT EXISTS (SELECT pk_idEspecialista FROM CLINICA.ESPECIALISTA WHERE pk_idEspecialista = 'ME-0001') THEN
		idEspecialista = 'ME-0001';
	ELSE
		idEspecialista := (SELECT pk_idEspecialista FROM CLINICA.ESPECIALISTA ORDER BY pk_idEspecialista DESC LIMIT 1);
		idEspecialistaAux := (SELECT SUBSTRING(idEspecialista, 4, 7));
		idEspecialistaAux := CAST(idEspecialistaAux AS INT)+1;
		
		IF idEspecialistaAux < '9' THEN
				idEspecialista = 'ME-000' || idEspecialistaAux;
			ELSEIF idEspecialistaAux BETWEEN '10' AND '99' THEN
				idEspecialista = 'ME-00' || idEspecialistaAux;
			ELSEIF idEspecialistaAux BETWEEN '100' AND '999' THEN
				idEspecialista = 'ME-0' || idEspecialistaAux;
			END IF;
	END IF;
	
	INSERT INTO CLINICA.ESPECIALISTA VALUES (idEspecialista, nombre, apellido, sexo, fechaNacimiento, especialidad);
	
	RAISE NOTICE 'ESPECIALISTA INGRESADO CORRECTAMENTE';

END; $$;
 �   DROP PROCEDURE clinica.insertarespecialista(IN nombre character varying, IN apellido character varying, IN sexo character, IN fechanacimiento date, IN especialidad character varying);
       clinica          postgres    false    5            �            1255    16539 �   insertarpacienteexpediente(character varying, character varying, character, date, character varying, character varying, character, character varying, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE clinica.insertarpacienteexpediente(IN nombre character varying, IN apellido character varying, IN sexo character, IN fechanacimiento date, IN ciudad character varying, IN estado character varying, IN telefono character, IN tiposangre character varying, IN tipoalergia character varying, IN padecimientocro character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	idPaciente CHAR(6);
	idPacienteAux CHAR(4);
	fechaCreacion TIMESTAMP := (SELECT LEFT (CAST(CURRENT_TIMESTAMP AS CHAR(30)), 19));
BEGIN

	IF NOT EXISTS (SELECT pk_idPaciente FROM CLINICA.PACIENTE WHERE pk_idPaciente = 'P-0001') THEN
		idPaciente = 'P-0001';
	ELSE
		idPaciente := (SELECT pk_idPaciente FROM CLINICA.PACIENTE ORDER BY pk_idPaciente DESC LIMIT 1);
		idPacienteAux := (SELECT SUBSTRING(idPaciente, 3, 6));
		idPAcienteAux := CAST(idPacienteAux AS INT)+1;
		
		IF idPacienteAux < '9' THEN
			idPaciente = 'P-00' || idPacienteAux;
		ELSEIF idPacienteAux BETWEEN '10' AND '99' THEN
			idPaciente = 'P-0' || idPacienteAux;
		ELSEIF idPacienteAux BETWEEN '100' AND '999' THEN
			idPaciente = 'P-' || idPacienteAux;
		END IF;
	END IF;
	
	INSERT INTO CLINICA.PACIENTE VALUES (idPaciente, nombre, apellido, sexo, fechaNacimiento, ciudad, estado, telefono);
	
	INSERT INTO CLINICA.EXPEDIENTE VALUES (idPaciente, tipoSangre, tipoalergia, padecimientoCro, fechaCreacion);
	
	RAISE NOTICE 'PACIENTE Y EXPEDIENTE INGRESADO CORRECTAMENTE';
	
END; $$;
 U  DROP PROCEDURE clinica.insertarpacienteexpediente(IN nombre character varying, IN apellido character varying, IN sexo character, IN fechanacimiento date, IN ciudad character varying, IN estado character varying, IN telefono character, IN tiposangre character varying, IN tipoalergia character varying, IN padecimientocro character varying);
       clinica          postgres    false    5            �            1255    16532    loop(integer)    FUNCTION     �   CREATE FUNCTION clinica.loop(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i INT := 0;
BEGIN

	FOR i IN 1..n LOOP
		RAISE NOTICE 'CONTADOR %', i;
	END LOOP;
	
END;
$$;
 '   DROP FUNCTION clinica.loop(n integer);
       clinica          postgres    false    5            �            1255    16534    loopcadados(integer)    FUNCTION     �   CREATE FUNCTION clinica.loopcadados(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i INT = 0;
BEGIN

	FOR i IN 0..n BY 2 LOOP
		RAISE NOTICE 'CONTADOR %', i;
	END LOOP;
	
END;
$$;
 .   DROP FUNCTION clinica.loopcadados(n integer);
       clinica          postgres    false    5            �            1255    16533    loopinverso(integer)    FUNCTION     �   CREATE FUNCTION clinica.loopinverso(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	i INT = 0;
BEGIN

	FOR i IN REVERSE n..1 LOOP
		RAISE NOTICE 'CONTADOR %', i;
	END LOOP;
	
END;
$$;
 .   DROP FUNCTION clinica.loopinverso(n integer);
       clinica          postgres    false    5            �            1255    16531    mesesano(integer)    FUNCTION     �  CREATE FUNCTION clinica.mesesano(nmes integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE 
	mensaje VARCHAR(30) := 'El número del mes es: ';
BEGIN
	
	CASE
		WHEN nMes = 1 THEN
			RETURN mensaje || 'Enero';
		WHEN nMes = 2 THEN
			RETURN mensaje || 'Febrero';
		WHEN nMes = 3 THEN
			RETURN mensaje || 'Marzo';
		WHEN nMes = 4 THEN
			RETURN mensaje || 'Abril';
		WHEN nMes = 5 THEN
			RETURN mensaje || 'Mayo';
		WHEN nMes = 6 THEN
			RETURN mensaje || 'Junio';
		WHEN nMes = 7 THEN
			RETURN mensaje || 'Julio';
		WHEN nMes = 8 THEN
			RETURN mensaje || 'Agosto';
		WHEN nMes = 9 THEN
			RETURN mensaje || 'Septiembre';
		WHEN nMes = 10 THEN
			RETURN mensaje || 'Octubre';
		WHEN nMes = 11 THEN
			RETURN mensaje || 'Noviembre';
		WHEN nMes = 12 THEN
			RETURN mensaje || 'Diciembre';
		ELSE
			RETURN 'El número no corresponde a un mes del año';
	END CASE;
			
END;
$$;
 .   DROP FUNCTION clinica.mesesano(nmes integer);
       clinica          postgres    false    5            �            1255    16525 $   multiplicarnumeros(integer, integer)    FUNCTION     �   CREATE FUNCTION clinica.multiplicarnumeros(num1 integer, num2 integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN num1 * num2;
END;
$$;
 F   DROP FUNCTION clinica.multiplicarnumeros(num1 integer, num2 integer);
       clinica          postgres    false    5            �            1255    16537    numerosimpares(integer)    FUNCTION     �   CREATE FUNCTION clinica.numerosimpares(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	i INT := 0;
BEGIN

	WHILE i < n LOOP
		IF (i%2)<>0 THEN
			RAISE NOTICE 'CONTADOR %', i;
		END IF;
		i = i + 1;
	END LOOP;

END;
$$;
 1   DROP FUNCTION clinica.numerosimpares(n integer);
       clinica          postgres    false    5            �            1255    16536    numerospares(integer)    FUNCTION     �   CREATE FUNCTION clinica.numerospares(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	i INT := 0;
BEGIN

	WHILE i < n LOOP
		IF (i%2)=0 THEN
			RAISE NOTICE 'CONTADOR %', i;
		END IF;
		i = i + 1;
	END LOOP;

END;
$$;
 /   DROP FUNCTION clinica.numerospares(n integer);
       clinica          postgres    false    5            �            1255    16528    nummayormenor(integer, integer)    FUNCTION     +  CREATE FUNCTION clinica.nummayormenor(n1 integer, n2 integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF n1 > n2 THEN
		RETURN 'EL NÚMERO MAYOR ES: '||n1;
	ELSEIF n1<n2 THEN
		RETURN 'EL NÚMERO MAYOR ES: '||n2;
	ELSE
		RETURN 'LOS NÚMEROS SON INGUALES';
	END IF;
END;
$$;
 =   DROP FUNCTION clinica.nummayormenor(n1 integer, n2 integer);
       clinica          postgres    false    5            �            1255    16547    realizarcita(clinica.id_cita) 	   PROCEDURE     H  CREATE PROCEDURE clinica.realizarcita(IN idcita clinica.id_cita)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	status CHAR(10) := (SELECT status FROM CLINICA.AGENDAR_CITA WHERE fk_idCita = idCita);
BEGIN

	IF NOT EXISTS (SELECT pk_idCita FROM CLINICA.CITA WHERE pk_idCita = idCita) THEN
		RAISE NOTICE 'EL ID DE LA CITA NO EXISTE EN LA BASE DE DATOS';
	ELSEIF status = 'CANCELADA' THEN
		RAISE NOTICE 'LA CITA YA HA SIDO CANCELADA';
	ELSE
		UPDATE CLINICA.AGENDAR_CITA SET status = 'REALIZADA' WHERE fk_idCita = idCita;
		
		RAISE NOTICE 'CITA REALIZADA CORRECTAMENTE';
	END IF;

END; $$;
 @   DROP PROCEDURE clinica.realizarcita(IN idcita clinica.id_cita);
       clinica          postgres    false    876    5            �            1255    16524    sumanumeros(integer, integer)    FUNCTION     �   CREATE FUNCTION clinica.sumanumeros(num1 integer, num2 integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN num1 + num2;
END;
$$;
 ?   DROP FUNCTION clinica.sumanumeros(num1 integer, num2 integer);
       clinica          postgres    false    5            �            1255    16535    while(integer)    FUNCTION     �   CREATE FUNCTION clinica.while(n integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	i INT := 0;
BEGIN

	WHILE i < n LOOP
		RAISE NOTICE 'CONTADOR %', i;
		i = i + 1;
	END LOOP;

END;
$$;
 (   DROP FUNCTION clinica.while(n integer);
       clinica          postgres    false    5            �            1259    16436    agendar_cita    TABLE     �  CREATE TABLE clinica.agendar_cita (
    fk_idcita clinica.id_cita NOT NULL,
    fk_idespecialista clinica.id_meespecialista NOT NULL,
    consultorio character varying(20) NOT NULL,
    fechacita date NOT NULL,
    horacita time without time zone NOT NULL,
    turno character varying(10) NOT NULL,
    status character varying(10) NOT NULL,
    observacionesconsulta character varying(100) NOT NULL
);
 !   DROP TABLE clinica.agendar_cita;
       clinica         heap    postgres    false    5    876    872            F           0    0    TABLE agendar_cita    ACL     �   GRANT ALL ON TABLE clinica.agendar_cita TO dba WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.agendar_cita TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    218            �            1259    16424    cita    TABLE     �   CREATE TABLE clinica.cita (
    pk_idcita clinica.id_cita NOT NULL,
    fk_idpaciente clinica.id_paciente,
    fecha date NOT NULL,
    hora time without time zone NOT NULL
);
    DROP TABLE clinica.cita;
       clinica         heap    postgres    false    876    868    5            G           0    0 
   TABLE cita    ACL     �   GRANT ALL ON TABLE clinica.cita TO dba WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.cita TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    217            �            1259    16549    datos_pacientes_personal    TABLE     <  CREATE TABLE clinica.datos_pacientes_personal (
    folio integer NOT NULL,
    tipomovimiento character varying(20),
    idpaciente clinica.id_paciente,
    nombrepaciente character varying(20),
    apellidopaciente character varying(20),
    usuario character varying(20),
    fecha timestamp without time zone
);
 -   DROP TABLE clinica.datos_pacientes_personal;
       clinica         heap    postgres    false    868    5            H           0    0    TABLE datos_pacientes_personal    ACL     �   GRANT ALL ON TABLE clinica.datos_pacientes_personal TO dba WITH GRANT OPTION;
GRANT INSERT ON TABLE clinica.datos_pacientes_personal TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    224            �            1259    16548 "   datos_pacientes_personal_folio_seq    SEQUENCE     �   CREATE SEQUENCE clinica.datos_pacientes_personal_folio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE clinica.datos_pacientes_personal_folio_seq;
       clinica          postgres    false    224    5            I           0    0 "   datos_pacientes_personal_folio_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE clinica.datos_pacientes_personal_folio_seq OWNED BY clinica.datos_pacientes_personal.folio;
          clinica          postgres    false    223            J           0    0 +   SEQUENCE datos_pacientes_personal_folio_seq    ACL     �   GRANT ALL ON SEQUENCE clinica.datos_pacientes_personal_folio_seq TO dba WITH GRANT OPTION;
GRANT ALL ON SEQUENCE clinica.datos_pacientes_personal_folio_seq TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    223            �            1259    16417    especialista    TABLE     ,  CREATE TABLE clinica.especialista (
    pk_idespecialista clinica.id_meespecialista NOT NULL,
    nombre character varying(20) NOT NULL,
    apellido character varying(20) NOT NULL,
    sexo character(1) NOT NULL,
    fechanacimiento date NOT NULL,
    especialidad character varying(30) NOT NULL
);
 !   DROP TABLE clinica.especialista;
       clinica         heap    postgres    false    5    872            K           0    0    TABLE especialista    ACL     �   GRANT ALL ON TABLE clinica.especialista TO dba WITH GRANT OPTION;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE clinica.especialista TO jefe_especialista WITH GRANT OPTION;
          clinica          postgres    false    216            �            1259    16453 
   expediente    TABLE       CREATE TABLE clinica.expediente (
    pk_idpaciente clinica.id_paciente NOT NULL,
    tiposangre character varying(20) NOT NULL,
    tipoalergia character varying(30) NOT NULL,
    padecimientocro character varying(50) NOT NULL,
    fechacreacion timestamp without time zone NOT NULL
);
    DROP TABLE clinica.expediente;
       clinica         heap    postgres    false    5    868            L           0    0    TABLE expediente    ACL     �   GRANT ALL ON TABLE clinica.expediente TO dba WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.expediente TO jefe_especialista WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.expediente TO especialista WITH GRANT OPTION;
          clinica          postgres    false    219            �            1259    16466    expediente_diagnostico    TABLE       CREATE TABLE clinica.expediente_diagnostico (
    folio integer NOT NULL,
    fk_idespecialista clinica.id_meespecialista,
    fk_idpaciente clinica.id_paciente,
    edad character(3) NOT NULL,
    peso character(3) NOT NULL,
    altura character(4) NOT NULL,
    imc character(5) NOT NULL,
    nivelpeso character(10) NOT NULL,
    presionarterial character(8) NOT NULL,
    diagnostico character varying(150) NOT NULL,
    recetario character varying(150) NOT NULL,
    fechacreacion timestamp without time zone NOT NULL
);
 +   DROP TABLE clinica.expediente_diagnostico;
       clinica         heap    postgres    false    5    872    868            M           0    0    TABLE expediente_diagnostico    ACL       GRANT ALL ON TABLE clinica.expediente_diagnostico TO dba WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.expediente_diagnostico TO jefe_especialista WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON TABLE clinica.expediente_diagnostico TO especialista WITH GRANT OPTION;
          clinica          postgres    false    221            �            1259    16465     expediente_diagnostico_folio_seq    SEQUENCE     �   CREATE SEQUENCE clinica.expediente_diagnostico_folio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE clinica.expediente_diagnostico_folio_seq;
       clinica          postgres    false    221    5            N           0    0     expediente_diagnostico_folio_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE clinica.expediente_diagnostico_folio_seq OWNED BY clinica.expediente_diagnostico.folio;
          clinica          postgres    false    220            O           0    0 )   SEQUENCE expediente_diagnostico_folio_seq    ACL     �   GRANT ALL ON SEQUENCE clinica.expediente_diagnostico_folio_seq TO dba WITH GRANT OPTION;
GRANT ALL ON SEQUENCE clinica.expediente_diagnostico_folio_seq TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    220            �            1259    16408    paciente    TABLE     _  CREATE TABLE clinica.paciente (
    pk_idpaciente clinica.id_paciente NOT NULL,
    nombre character varying(20) NOT NULL,
    apellido character varying(20) NOT NULL,
    sexo character(1) NOT NULL,
    fechanacimiento date NOT NULL,
    ciudad character varying(20) NOT NULL,
    estado character varying(20) NOT NULL,
    telefono character(10)
);
    DROP TABLE clinica.paciente;
       clinica         heap    postgres    false    868    5            P           0    0    TABLE paciente    ACL     �   GRANT ALL ON TABLE clinica.paciente TO dba WITH GRANT OPTION;
GRANT SELECT ON TABLE clinica.paciente TO especialista WITH GRANT OPTION;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE clinica.paciente TO recepcionista WITH GRANT OPTION;
          clinica          postgres    false    215            �            1259    16499    pacientes_masculinos    VIEW     �   CREATE VIEW clinica.pacientes_masculinos AS
 SELECT pk_idpaciente,
    nombre,
    apellido,
    sexo,
    fechanacimiento,
    ciudad,
    estado,
    telefono
   FROM clinica.paciente
  WHERE (sexo = 'M'::bpchar);
 (   DROP VIEW clinica.pacientes_masculinos;
       clinica          postgres    false    215    215    215    215    215    215    215    215    868    5            Q           0    0    TABLE pacientes_masculinos    ACL     J   GRANT ALL ON TABLE clinica.pacientes_masculinos TO dba WITH GRANT OPTION;
          clinica          postgres    false    222            �           2604    16552    datos_pacientes_personal folio    DEFAULT     �   ALTER TABLE ONLY clinica.datos_pacientes_personal ALTER COLUMN folio SET DEFAULT nextval('clinica.datos_pacientes_personal_folio_seq'::regclass);
 N   ALTER TABLE clinica.datos_pacientes_personal ALTER COLUMN folio DROP DEFAULT;
       clinica          postgres    false    224    223    224            �           2604    16469    expediente_diagnostico folio    DEFAULT     �   ALTER TABLE ONLY clinica.expediente_diagnostico ALTER COLUMN folio SET DEFAULT nextval('clinica.expediente_diagnostico_folio_seq'::regclass);
 L   ALTER TABLE clinica.expediente_diagnostico ALTER COLUMN folio DROP DEFAULT;
       clinica          postgres    false    221    220    221            9          0    16436    agendar_cita 
   TABLE DATA           �   COPY clinica.agendar_cita (fk_idcita, fk_idespecialista, consultorio, fechacita, horacita, turno, status, observacionesconsulta) FROM stdin;
    clinica          postgres    false    218   �       8          0    16424    cita 
   TABLE DATA           F   COPY clinica.cita (pk_idcita, fk_idpaciente, fecha, hora) FROM stdin;
    clinica          postgres    false    217   ��       >          0    16549    datos_pacientes_personal 
   TABLE DATA           �   COPY clinica.datos_pacientes_personal (folio, tipomovimiento, idpaciente, nombrepaciente, apellidopaciente, usuario, fecha) FROM stdin;
    clinica          postgres    false    224   c�       7          0    16417    especialista 
   TABLE DATA           q   COPY clinica.especialista (pk_idespecialista, nombre, apellido, sexo, fechanacimiento, especialidad) FROM stdin;
    clinica          postgres    false    216   0�       :          0    16453 
   expediente 
   TABLE DATA           m   COPY clinica.expediente (pk_idpaciente, tiposangre, tipoalergia, padecimientocro, fechacreacion) FROM stdin;
    clinica          postgres    false    219   
�       <          0    16466    expediente_diagnostico 
   TABLE DATA           �   COPY clinica.expediente_diagnostico (folio, fk_idespecialista, fk_idpaciente, edad, peso, altura, imc, nivelpeso, presionarterial, diagnostico, recetario, fechacreacion) FROM stdin;
    clinica          postgres    false    221   ��       6          0    16408    paciente 
   TABLE DATA           u   COPY clinica.paciente (pk_idpaciente, nombre, apellido, sexo, fechanacimiento, ciudad, estado, telefono) FROM stdin;
    clinica          postgres    false    215   U�       R           0    0 "   datos_pacientes_personal_folio_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('clinica.datos_pacientes_personal_folio_seq', 5, true);
          clinica          postgres    false    223            S           0    0     expediente_diagnostico_folio_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('clinica.expediente_diagnostico_folio_seq', 17, true);
          clinica          postgres    false    220            �           2606    16442    agendar_cita agendar_cita_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY clinica.agendar_cita
    ADD CONSTRAINT agendar_cita_pkey PRIMARY KEY (fk_idcita, fk_idespecialista);
 I   ALTER TABLE ONLY clinica.agendar_cita DROP CONSTRAINT agendar_cita_pkey;
       clinica            postgres    false    218    218            �           2606    16430    cita cita_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY clinica.cita
    ADD CONSTRAINT cita_pkey PRIMARY KEY (pk_idcita);
 9   ALTER TABLE ONLY clinica.cita DROP CONSTRAINT cita_pkey;
       clinica            postgres    false    217            �           2606    16556 6   datos_pacientes_personal datos_pacientes_personal_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY clinica.datos_pacientes_personal
    ADD CONSTRAINT datos_pacientes_personal_pkey PRIMARY KEY (folio);
 a   ALTER TABLE ONLY clinica.datos_pacientes_personal DROP CONSTRAINT datos_pacientes_personal_pkey;
       clinica            postgres    false    224            �           2606    16423    especialista especialista_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY clinica.especialista
    ADD CONSTRAINT especialista_pkey PRIMARY KEY (pk_idespecialista);
 I   ALTER TABLE ONLY clinica.especialista DROP CONSTRAINT especialista_pkey;
       clinica            postgres    false    216            �           2606    16473 2   expediente_diagnostico expediente_diagnostico_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY clinica.expediente_diagnostico
    ADD CONSTRAINT expediente_diagnostico_pkey PRIMARY KEY (folio);
 ]   ALTER TABLE ONLY clinica.expediente_diagnostico DROP CONSTRAINT expediente_diagnostico_pkey;
       clinica            postgres    false    221            �           2606    16459    expediente expediente_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY clinica.expediente
    ADD CONSTRAINT expediente_pkey PRIMARY KEY (pk_idpaciente);
 E   ALTER TABLE ONLY clinica.expediente DROP CONSTRAINT expediente_pkey;
       clinica            postgres    false    219            �           2606    16414    paciente paciente_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY clinica.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (pk_idpaciente);
 A   ALTER TABLE ONLY clinica.paciente DROP CONSTRAINT paciente_pkey;
       clinica            postgres    false    215            �           2606    16416    paciente paciente_telefono_key 
   CONSTRAINT     ^   ALTER TABLE ONLY clinica.paciente
    ADD CONSTRAINT paciente_telefono_key UNIQUE (telefono);
 I   ALTER TABLE ONLY clinica.paciente DROP CONSTRAINT paciente_telefono_key;
       clinica            postgres    false    215            �           2620    16568    paciente actualizado_paciente    TRIGGER     �   CREATE TRIGGER actualizado_paciente AFTER UPDATE ON clinica.paciente FOR EACH ROW EXECUTE FUNCTION clinica.actualizadopaciente();
 7   DROP TRIGGER actualizado_paciente ON clinica.paciente;
       clinica          postgres    false    254    215            �           2620    16558    paciente borrado_paciente    TRIGGER     z   CREATE TRIGGER borrado_paciente AFTER DELETE ON clinica.paciente FOR EACH ROW EXECUTE FUNCTION clinica.borradopaciente();
 3   DROP TRIGGER borrado_paciente ON clinica.paciente;
       clinica          postgres    false    215    253            �           2606    16443 (   agendar_cita agendar_cita_fk_idcita_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.agendar_cita
    ADD CONSTRAINT agendar_cita_fk_idcita_fkey FOREIGN KEY (fk_idcita) REFERENCES clinica.cita(pk_idcita) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY clinica.agendar_cita DROP CONSTRAINT agendar_cita_fk_idcita_fkey;
       clinica          postgres    false    218    4757    217            �           2606    16448 0   agendar_cita agendar_cita_fk_idespecialista_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.agendar_cita
    ADD CONSTRAINT agendar_cita_fk_idespecialista_fkey FOREIGN KEY (fk_idespecialista) REFERENCES clinica.especialista(pk_idespecialista) ON UPDATE CASCADE ON DELETE CASCADE;
 [   ALTER TABLE ONLY clinica.agendar_cita DROP CONSTRAINT agendar_cita_fk_idespecialista_fkey;
       clinica          postgres    false    218    216    4755            �           2606    16431    cita cita_fk_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.cita
    ADD CONSTRAINT cita_fk_idpaciente_fkey FOREIGN KEY (fk_idpaciente) REFERENCES clinica.paciente(pk_idpaciente) ON UPDATE CASCADE ON DELETE CASCADE;
 G   ALTER TABLE ONLY clinica.cita DROP CONSTRAINT cita_fk_idpaciente_fkey;
       clinica          postgres    false    215    4751    217            �           2606    16474 D   expediente_diagnostico expediente_diagnostico_fk_idespecialista_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.expediente_diagnostico
    ADD CONSTRAINT expediente_diagnostico_fk_idespecialista_fkey FOREIGN KEY (fk_idespecialista) REFERENCES clinica.especialista(pk_idespecialista) ON UPDATE CASCADE ON DELETE CASCADE;
 o   ALTER TABLE ONLY clinica.expediente_diagnostico DROP CONSTRAINT expediente_diagnostico_fk_idespecialista_fkey;
       clinica          postgres    false    216    221    4755            �           2606    16479 @   expediente_diagnostico expediente_diagnostico_fk_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.expediente_diagnostico
    ADD CONSTRAINT expediente_diagnostico_fk_idpaciente_fkey FOREIGN KEY (fk_idpaciente) REFERENCES clinica.paciente(pk_idpaciente) ON UPDATE CASCADE ON DELETE CASCADE;
 k   ALTER TABLE ONLY clinica.expediente_diagnostico DROP CONSTRAINT expediente_diagnostico_fk_idpaciente_fkey;
       clinica          postgres    false    221    4751    215            �           2606    16460 (   expediente expediente_pk_idpaciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY clinica.expediente
    ADD CONSTRAINT expediente_pk_idpaciente_fkey FOREIGN KEY (pk_idpaciente) REFERENCES clinica.paciente(pk_idpaciente) ON UPDATE CASCADE ON DELETE CASCADE;
 S   ALTER TABLE ONLY clinica.expediente DROP CONSTRAINT expediente_pk_idpaciente_fkey;
       clinica          postgres    false    4751    215    219            9   �   x���K� �5��`fh�;�,������x�s�TLK}PV|�g�m-  Y��m|7T}Ӗ��@��`<�6�З�a�;��0o��ڄ�wD�"�fDoH������3�m@��3T�L��2y`TĨC)�H1C�Ns���bRi�ٗ,b��щ��\:)�؁�/!lH���o]eN	�i!��T�5H�=���L�!      8   �   x�]�K
� �u���O�U���0���c��������y3 :>̙����K�"��aCD�l%��BUI�Dt��RrY
5%m�IW��%��a���F��%�d�"��v�]��s#�D� �e5Nn���R�3�UC      >   �   x���K
�0����*�@%7IU:��4մvP)�HZI݉Krc�F��p�?a�:GI
��sT�ќlN�L����O;�� ��b�q���B&��|E3SRl.g�4&�Sg�tf����B��GA[g�+���޷��?�����n2�_�o��q�vw���;5�䄅��H�Y��d!1T�Ƒ�l=d�]N�XV      7   �   x�m�AN�@E��)�@�gi��g�v�ܦR+nő�N	BT�����~�\#����FJ��0�뻶Fg��8����J��7�������)^!�v�Õ���"m�&Nъ�X�d�����x�K$He����k6���t���W\40�9�q(V�m��=�@:ƯO�)[���B�L]�\�׾y첃������ƾ�x����KM^      :   �   x�}�M� F�p
.@3���-1$(F��z�s�v��	+��|���@��Mf��}{��,�E����ŋ	�)9T\ h���?� ~3#��ؙ�	�Q&F�f�1�9؈��ø�T����ͬ��f��Ӊ�����,+/�>D�c��uW_�2m��b5ydܰI3�������͙Uٹ��`дJ����A)�  �9      <   e  x���K��0 е9E. �v��Z�E��P�۹�9��
)m?�;��mi�E��r�5�U��P��ow���dk����I��D,�����,(	�4��B/>�ӽ����}x+�"r*28o@��I%�9�F��n�C��;ѧ�"��A�<�&�>+�E�I�Q���@|�1�bwj���<���÷bS�fWlRQ�i��&_=��,bL� �*ʼƭ�����h'�}NJ�'1%5T%����1w\�s����Z������ۆ��R�J�+��%�o�>�RS�����2�-!%W��Α��wd�K��֥��$���ϑ��IȰ���9�|?1�/�T{�A<�h�<H���(����      6   �  x�m�MR�0���SpS���R���XA�SŅXΙ��t$a�*Y������!$aJq�M(�<�z�z�^X�ǿi�/������u�3�`��	c��4���
{B`�c,%����S�c�V	I�Jhxh4?�K�,b�YD�O�iᝥF`�� ��ǿ��W��%a�P�fV�7�Va��1�!����w�Gѓ���hE�;�`O��	��|������*'�m�o�g��>S���Wjذaǡ5pH��<��]8�:4��=����^�����K��AU6?@�DB�t��T-��𼤳�|���n��lId�GA�Y�W�6|��X��U�rJ��B�Jz^"��Z�粐+���6j��0�sJ�c.)pg|�E��"9�_����:$ӽ�w]�7���     