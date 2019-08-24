LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.uniform;
USE ieee.math_real.floor;

ENTITY test IS
	PORT (
		up_in, down_in, left_in, right_in : IN STD_LOGIC;
		clk27M									 : IN STD_LOGIC;
		reset, inicia							 : IN STD_LOGIC;
		VGA_R, VGA_G, VGA_B					 : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
		VGA_HS, VGA_VS							 : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE behavior OF TEST IS
	COMPONENT vgacon IS
		GENERIC (
			NUM_HORZ_PIXELS : NATURAL := 64;	-- Number of horizontal pixels
			NUM_VERT_PIXELS : NATURAL := 48	-- Number of vertical pixels
		);
		PORT (
			clk27M, rstn              : IN STD_LOGIC;
			write_clk, write_enable   : IN STD_LOGIC;
			write_addr                : IN INTEGER RANGE 0 TO NUM_HORZ_PIXELS * NUM_VERT_PIXELS - 1;
			data_in                   : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			red, green, blue          : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
			hsync, vsync              : OUT STD_LOGIC
		);
	END COMPONENT;
	
	CONSTANT CONS_CLOCK_DIV : INTEGER := 6000000;
	CONSTANT HORZ_SIZE : INTEGER := 15;
	CONSTANT VERT_SIZE : INTEGER := 15;
	SIGNAL slow_clock : STD_LOGIC;
	SIGNAL video_address: INTEGER RANGE 0 TO HORZ_SIZE * VERT_SIZE - 1;
	SIGNAL video_word: STD_LOGIC_VECTOR (2 DOWNTO 0);
	
	--snake
	CONSTANT snake_tam_max  : INTEGER := 10;
	CONSTANT tela_tamanho   : INTEGER := HORZ_SIZE * VERT_SIZE - 1;
	TYPE tela_array IS ARRAY(INTEGER RANGE <>) OF INTEGER RANGE -1 TO snake_tam_max;
	SIGNAL vetor_tela 		: tela_array(0 TO tela_tamanho);
	SIGNAL tela_endereco 	: INTEGER RANGE 0 TO tela_tamanho;
	SIGNAL snake_tamanho 	: INTEGER RANGE 1 TO snake_tam_max;
	SIGNAL snake_orientacao : INTEGER RANGE -HORZ_SIZE TO HORZ_SIZE := 1;
	
	SIGNAL cabeca_endereco  : INTEGER RANGE 0 TO tela_tamanho;
	
	SIGNAL direcao_anterior : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
	CONSTANT cima 				: STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	CONSTANT direita  		: STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
	CONSTANT baixo 			: STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
	CONSTANT esquerda 		: STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
	
	--procedimento que zera o mapa
	PROCEDURE limpaMapa IS
	BEGIN
		vetor_tela <= (others => 0);
	END limpaMapa;
	
	--procedimento que cria a cobra 
	PROCEDURE criaSnake IS
	BEGIN
		cabeca_endereco <= tela_tamanho/2;
		vetor_tela(cabeca_endereco) <= snake_tamanho;
	END criaSnake;

	--procedimento para geracao de comidas da cobra
	PROCEDURE geraComida IS
	BEGIN
		vetor_tela(50) <= -1;
	END geraComida;
	
	--procedimento que inicializa o jogo
	PROCEDURE inicializa IS
	BEGIN
		limpaMapa;
		snake_tamanho <= 1;
		criaSnake;
		geraComida;
	END inicializa;

	--procedimento para encerrar jogo
	PROCEDURE endgame IS
	BEGIN
		inicializa;
	END endgame;
	
	--procedimento que faz a cobra andar no vetor da tela
	PROCEDURE moveSnake IS
	VARIABLE comeu : STD_LOGIC := '0';
	BEGIN
	
		--VERIFICA FIM DE JOGO
		--CASO CONTRARIO MOVE COBRA NO VETOR
		--caso a cobra vá para uma posição que contenha seu corpo
		IF vetor_tela(cabeca_endereco + snake_orientacao) > 0 THEN
			endgame;
		--limite superior da tela
		ELSIF cabeca_endereco + snake_orientacao < 0 THEN
			endgame;
		--limite inferior da tela
		ELSIF cabeca_endereco + snake_orientacao > tela_tamanho + 1 THEN
			endgame;
		--limite direito da tela
		ELSIF (cabeca_endereco + snake_orientacao) mod HORZ_SIZE = 0 THEN
			endgame;
		--limite esquerdo da tela
		ELSIF cabeca_endereco mod HORZ_SIZE = 0 AND snake_orientacao = -1 THEN
			endgame;
		ELSE
			--verifica e faz tratamento dos dados se a cobra capturou a comida
			IF vetor_tela(cabeca_endereco + snake_orientacao) = -1 THEN
				comeu := '1';
				snake_tamanho <= snake_tamanho + 1;
				geraComida;
			END IF;
			
			--projeta a cabeça da cobra para a direção estipulada
			vetor_tela(cabeca_endereco + snake_orientacao) <= snake_tamanho;
			
			
			vetor_tela(cabeca_endereco) <= snake_tamanho - 1;
			
			--tratamento dos dados caso a cobra nao tenha capturado a comida
			IF comeu = '0' THEN
				FOR i IN 0 TO tela_tamanho LOOP
					IF vetor_tela(i) > 0 AND vetor_tela(i) >= snake_tamanho - 1  THEN
						vetor_tela(i) <= vetor_tela(i) - 1;
					END IF;
				END LOOP;
			END IF;
			--atualiza posicao da cebeca
			cabeca_endereco <= cabeca_endereco + snake_orientacao;
		END IF;
	END moveSnake;

	--procedimento que controla a direcao da cobra
	PROCEDURE controla_direcao IS 
	BEGIN
		--limita direcao a partir da direcao anterior
		IF up_in = '0' AND direcao_anterior /= baixo THEN
			snake_orientacao <= -HORZ_SIZE;
			direcao_anterior <= cima;
		ELSIF right_in = '0' AND direcao_anterior /= esquerda THEN
			snake_orientacao <= 1;
			direcao_anterior <= direita;
		ELSIF down_in = '0' AND direcao_anterior /= cima THEN
			snake_orientacao <= HORZ_SIZE;
			direcao_anterior <= baixo;
		ELSIF left_in = '0' AND direcao_anterior /= direita THEN
			snake_orientacao <= -1;
			direcao_anterior <= esquerda;
		END IF;
	END controla_direcao;
	
BEGIN

	--processo controlador
	main_process:
	PROCESS(slow_clock)
	BEGIN
		--switch assincrono para iniciar o jogo
		IF inicia = '1' THEN
			inicializa;
		ELSIF rising_edge(slow_clock) THEN
			controla_direcao;
			moveSnake;
		END IF;
	END PROCESS;
				  
	--transfere informacoes do vetor que contem os dados do jogo
	atualiza:
	PROCESS(clk27M, tela_endereco)
	BEGIN
		IF rising_edge(clk27M) THEN
			IF tela_endereco > tela_tamanho-1 THEN
				tela_endereco <= 0;
			ELSE
				--video_address: seleciona posicao da tela
				--video_word: escreve na tela
				video_address <= tela_endereco;
				IF vetor_tela(tela_endereco) = 0 THEN 
					video_word <= "000";
				ELSIF vetor_tela(tela_endereco) = snake_tamanho THEN
					video_word <= "111";
				ELSIF vetor_tela(tela_endereco) > 0 THEN
					video_word <= "100";
				ELSE 
					video_word <= "001";
				END IF;
				tela_endereco <= tela_endereco + 1; 
			END IF;
		END IF;
	END PROCESS;

	
	vga_component: vgacon
	GENERIC MAP (
		NUM_HORZ_PIXELS => HORZ_SIZE,
		NUM_VERT_PIXELS => VERT_SIZE
	) PORT MAP (
		clk27M			=> clk27M		,
		rstn			=> reset		,
		write_clk		=> clk27M		,
		write_enable	=> '1'			,
		write_addr      => video_address,
		data_in         => video_word	,
		red				=> VGA_R		,
		green			=> VGA_G		,
		blue			=> VGA_B		,
		hsync			=> VGA_HS		,
		vsync			=> VGA_VS		
	);
	
	--cria clock reduzido denominaso slow_clock
	clock_divider:
	PROCESS (clk27M, reset)
		VARIABLE i : INTEGER := 0;
	BEGIN
		IF (reset = '0') THEN
			i := 0;
			slow_clock <= '0';
		ELSIF (rising_edge(clk27M)) THEN
			IF (i <= CONS_CLOCK_DIV/2) THEN
				i := i + 1;
				slow_clock <= '0';
			ELSIF (i < CONS_CLOCK_DIV-1) THEN
				i := i + 1;
				slow_clock <= '1';
			ELSE		
				i := 0;
			END IF;	
		END IF;
	END PROCESS;
	
END ARCHITECTURE;