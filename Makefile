filename=alternatecharging
#sname=altsupp

pdf:
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}
	pdflatex ${filename}
	open -a TexShop ${filename}.pdf

supp:
	pdflatex ${sname}
	bibtex ${sname}||true
	pdflatex ${sname}
	pdflatex ${sname}
	open -a TexShop ${sname}.pdf

figs:
	bash compile_figures

diff:
	bash dodiff

clean:
	rm -f ${filename}.{ps,pdf,log,aux,out,dvi,bbl,blg}
	rm -f ${sname}.{ps,pdf,log,aux,out,dvi,bbl,blg}

all:
	make clean
#	make figs
	make pdf
#	make supp
	make diff
