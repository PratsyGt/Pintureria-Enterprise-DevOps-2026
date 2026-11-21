
"""PDF paginado con encabezados repetidos y celdas ajustadas al ancho de página."""

from io import BytesIO
from xml.sax.saxutils import escape
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet

from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    LongTable,
    TableStyle
)


def crear_pdf(titulo, tablas, subtitulo=''):

    buffer = BytesIO()

    styles = getSampleStyleSheet()

    styles['BodyText'].fontSize = 8
    styles['BodyText'].leading = 11


    doc = SimpleDocTemplate(
        buffer,
        pagesize=landscape(A4),
        rightMargin=28,
        leftMargin=28,
        topMargin=32,
        bottomMargin=35,
        title=titulo,
        author='Pinturería 2026'
    )


    para = lambda value: Paragraph(
        escape(
            str(
                value if value is not None else '—'
            )
        ),
        styles['BodyText']
    )


    story = [
        Paragraph(
            'Pinturería 2026',
            styles['Title']
        ),

        Paragraph(
            escape(titulo),
            styles['Heading2']
        ),

        para(subtitulo),

        Spacer(1, 14)
    ]


    for section in tablas:

        story.append(
            Paragraph(
                escape(section['titulo']),
                styles['Heading3']
            )
        )


        if not section['rows']:

            story.append(
                para(
                    'No hay registros para los filtros seleccionados.'
                )
            )

            continue


        data = [
            [para(v) for v in section['headers']]
        ] + [
            [para(v) for v in row]
            for row in section['rows']
        ]


        table = LongTable(
            data,
            colWidths=[
                doc.width / len(section['headers'])
            ] * len(section['headers']),
            repeatRows=1,
            hAlign='LEFT'
        )


        table.setStyle(
            TableStyle(
                [
                    (
                        'BACKGROUND',
                        (0, 0),
                        (-1, 0),
                        colors.HexColor('#e5e7eb')
                    ),

                    (
                        'ROWBACKGROUNDS',
                        (0, 1),
                        (-1, -1),
                        [
                            colors.white,
                            colors.HexColor('#f7f7f7')
                        ]
                    ),

                    (
                        'VALIGN',
                        (0, 0),
                        (-1, -1),
                        'TOP'
                    ),

                    (
                        'BOTTOMPADDING',
                        (0, 0),
                        (-1, -1),
                        7
                    ),

                    (
                        'TOPPADDING',
                        (0, 0),
                        (-1, -1),
                        7
                    ),

                    (
                        'LINEBELOW',
                        (0, 0),
                        (-1, 0),
                        .5,
                        colors.grey
                    )
                ]
            )
        )


        story.extend(
            [
                table,
                Spacer(1, 14)
            ]
        )


    def footer(canvas, document):

        canvas.saveState()

        canvas.setFont(
            'Helvetica',
            8
        )

        canvas.drawString(
            28,
            18,
            'Pinturería 2026 · Reporte de consulta'
        )

        canvas.drawRightString(
            landscape(A4)[0] - 28,
            18,
            f'Página {document.page}'
        )

        canvas.restoreState()


    doc.build(
        story,
        onFirstPage=footer,
        onLaterPages=footer
    )


    return buffer.getvalue()
