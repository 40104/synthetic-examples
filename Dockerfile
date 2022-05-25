FROM ubuntu:20.04 AS initial

RUN \
	apt-get update -yq && \
	apt-get upgrade -yq && \
	apt-get install -yq tzdata

ENV TZ "Europe/Moscow"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	dpkg-reconfigure -f noninteractive tzdata

RUN \
	apt-get install -yq clang git valgrind && \
	apt-get clean

RUN \
	git clone https://github.com/pwndbg/pwndbg && \
	cd pwndbg && \
	./setup.sh && \
	apt-get clean && \
	cd ../
	 
RUN mkdir /binaries-clean && \
    mkdir /binaries-sanitized

COPY ./synthetic-tests-sources /tests

##############################
#	  COMPILATION SANIT
##############################

FROM initial as before-compile

RUN clang++ -fsanitize=address \
		    -O1 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-sanitized/use-after-free \
		    /tests/use-after-free.cpp && \
			\
	clang++ -fsanitize=address \
		    -O1 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-sanitized/heap-buffer-overflow \
		    /tests/heap-buffer-overflow.cpp && \
			\
	clang++ -fsanitize=address \
		    -O1 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-sanitized/stack-buffer-overflow \
		    /tests/stack-buffer-overflow.cpp && \
			\
	clang++ -fsanitize=address \
		    -O1 \
		    -fno-omit-frame-pointer \
		    -g \
		    -o /binaries-sanitized/global-buffer-overflow \
		    /tests/global-buffer-overflow.cpp && \
			\
	clang 	-fsanitize=address \
		  	-O \
		  	-g \
		  	-o /binaries-sanitized/use-after-return \
		  	/tests/use-after-return.c && \
		  	\
	clang 	-O \
		  	-g \
		  	-fsanitize=address \
		  	-fsanitize-address-use-after-scope \
		  	-o /binaries-sanitized/use-after-scope \
		  	/tests/use-after-scope.c && \
		  	\
	clang++	-fsanitize=address \
		  	-g \
		  	/tests/init-order.a.cpp \
		  	/tests/init-order.b.cpp \
		  	-o /binaries-sanitized/order-a-to-b && \
			\
	clang++	-fsanitize=address \
		  	-g \
		  	/tests/init-order.b.cpp \
		  	/tests/init-order.a.cpp \
		  	-o /binaries-sanitized/order-b-to-a && \
			\
	clang 	-fsanitize=address \
			-g \
			/tests/memory-leak.c \
			-o /binaries-sanitized/memory-leak

##############################
#	  COMPILATION CLEAN
##############################

RUN clang++ -O0 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-clean/use-after-free \
		    /tests/use-after-free.cpp && \
			\
	clang++ -O0 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-clean/heap-buffer-overflow \
		    /tests/heap-buffer-overflow.cpp && \
			\
	clang++ -O0 \
		    -fno-omit-frame-pointer \
		    -g -ggdb \
		    -o /binaries-clean/stack-buffer-overflow \
		    /tests/stack-buffer-overflow.cpp && \
			\
	clang++ -O0 \
		    -fno-omit-frame-pointer \
		    -g \
		    -o /binaries-clean/global-buffer-overflow \
		    /tests/global-buffer-overflow.cpp && \
			\
	clang 	-O0 \
		  	-g \
		  	-o /binaries-clean/use-after-return \
		  	/tests/use-after-return.c && \
		  	\
	clang 	-O0 \
		  	-g \
		  	-o /binaries-clean/use-after-scope \
		  	/tests/use-after-scope.c && \
		  	\
	clang++	-g \
		  	/tests/init-order.a.cpp \
		  	/tests/init-order.b.cpp \
		  	-o /binaries-clean/order-a-to-b && \
			\
	clang++	-g \
		  	/tests/init-order.b.cpp \
		  	/tests/init-order.a.cpp \
		  	-o /binaries-clean/order-b-to-a && \
			\
	clang   -g \
			/tests/memory-leak.c \
			-o /binaries-clean/memory-leak

