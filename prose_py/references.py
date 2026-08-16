"""Numbered references list for the main manuscript.

Ported verbatim from v10.2 (paragraphs 116–162 of the v10.2 docx). Each
reference is a plain string; the module numbers them 1..N at render time to
avoid maintaining two parallel numbers.
"""
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.shared import Inches, Pt

from tables.docx_helpers import FONT_NAME, BODY_FS, H1


REFERENCES = [
    "Burrows B, Fletcher CM, Heard BE, Jones NL, Wootliff JS. The "
    "emphysematous and bronchial types of chronic airways obstruction: a "
    "clinicopathological study of patients in London and Chicago. Lancet "
    "1966;1:830–835.",

    "Snider GL. Chronic obstructive pulmonary disease: a definition and "
    "implications of structural determinants of airflow obstruction for "
    "epidemiology. Am Rev Respir Dis 1989;140:S3–S8.",

    "Agusti A, Calverley PM, Celli B, et al. Characterisation of COPD "
    "heterogeneity in the ECLIPSE cohort. Respir Res 2010;11:122.",

    "Camiciottoli G, Bigazzi F, Paoletti P, et al. Pulmonary function and "
    "sputum characteristics predict computed tomography phenotype and "
    "severity of COPD. Eur Respir J 2013;42:626–635.",

    "Castaldi PJ, Xu Z, Young K, et al. Heterogeneity and progression of "
    "chronic obstructive pulmonary disease: emphysema-predominant and "
    "non-emphysema-predominant disease. Am J Epidemiol 2023;192:1647–1658.",

    "Bhatt SP, Silverman EK, Crapo JD. Beyond spirometry in COPD: expanding "
    "the diagnostic paradigm. ERJ Open Res 2026;12:00045-2026. "
    "doi: 10.1183/23120541.00045-2026.",

    "Celli BR, Cote CG, Marin JM, et al. The body-mass index, airflow "
    "obstruction, dyspnea, and exercise capacity index in chronic obstructive "
    "pulmonary disease. N Engl J Med 2004;350:1005-1012.",

    "Lowe KE, Regan EA, Anzueto A, et al. COPDGene 2019: redefining the "
    "diagnosis of chronic obstructive pulmonary disease. Chronic Obstr Pulm "
    "Dis 2019;6:384-399.",

    "Stolz D, Mkorombindo T, Schumann DM, et al. Towards the elimination of "
    "chronic obstructive pulmonary disease: a Lancet Commission. Lancet "
    "2022;400:921-972.",

    "Morelli T, Geeves ME, Mohammed A, et al. Beyond spirometry: understanding "
    "COPD origins to support a new diagnostic approach. ERJ Open Res "
    "2026;12:00885-2025.",

    "Bhatt SP, Abadi E, Anzueto A, et al. A multidimensional diagnostic "
    "approach for chronic obstructive pulmonary disease. JAMA "
    "2025;333:2164-2175.",

    "Wu F, Huang S, Zhou K, et al. Clinical validation of a multidimensional "
    "diagnostic approach for COPD in Chinese individuals. Chest "
    "2026;169:371-384.",

    "Occhipinti M, Paoletti M, Bartholmai BJ, et al. Spirometric assessment of "
    "emphysema presence and severity as measured by quantitative CT and "
    "CT-based radiomics in COPD. Respir Res 2019;20:101.",

    "Occhipinti M, Paoletti M, Crapo JD, et al. Validation of a method to "
    "assess emphysema severity by spirometry in the COPDGene study. Respir "
    "Res 2020;21:103.",

    "Luoto J, Pihlsgård M, Pistolesi M, et al. Emphysema severity index (ESI) "
    "associated with respiratory death in a large Swedish general population. "
    "Respir Med 2022;200:106899.",

    "Maio S, Viegi G, Carrozzi L, et al. Emphysema Severity Index (ESI): a "
    "new spirometric parameter in epidemiology. ERJ Open Res 2026; in press. "
    "doi:10.1183/23120541.01587-2025.",

    "Regan EA, Hokanson JE, Murphy JR, et al. Genetic epidemiology of COPD "
    "(COPDGene) study design. COPD 2010;7:32–43.",

    "Lynch DA, Austin JH, Hogg JC, et al. CT-definable subtypes of chronic "
    "obstructive pulmonary disease: a statement of the Fleischner Society. "
    "Radiology 2015;277:192–205.",

    "Schroeder JD, McKenzie AS, Zach JA, et al. Relationships between airflow "
    "obstruction and quantitative CT measurements of emphysema, air trapping, "
    "and airways in subjects with and without chronic obstructive pulmonary "
    "disease. AJR Am J Roentgenol 2013;201:W460–W470.",

    "Galbán CJ, Han MK, Boes JL, et al. Computed tomography-based biomarker "
    "provides unique signature for diagnosis of COPD phenotypes and disease "
    "progression. Nat Med 2012;18:1711–1715.",

    "Macklem PT, Mead J. Resistance of central and peripheral airways "
    "measured by a retrograde catheter. J Appl Physiol 1967;22:395-401.",

    "Saltzman HP, Ciulla EM, Kuperman AS. The spirographic \"kink\": a sign "
    "of emphysema. Chest 1976;69:51-55.",

    "Pellegrino R, Crimi C, Gobbi A, et al. Severity grading of chronic "
    "obstructive pulmonary disease: the confounding effect of phenotype and "
    "thoracic gas compression. J Appl Physiol 2015;118:796-802.",

    "Stanojevic S, Kaminsky DA, Miller MR, et al. ERS/ATS technical standard "
    "on interpretative strategies for routine lung function tests. Eur Respir "
    "J 2022;60:2101499.",

    "Dal Negro RW, Turco P, Povero M, Pistolesi M. Basal computation of "
    "Emphysema Severity Index (ESI) in COPD patients is not affected by "
    "bronchodilation. EC Pulmon Respir Med 2024;14:01-09.",

    "Albert P, Agusti A, Edwards L, et al. Bronchodilator responsiveness as a "
    "phenotypic characteristic of established chronic obstructive pulmonary "
    "disease. Thorax 2012;67:701-708.",

    "Hoffman EA, Ahmed FS, Baumhauer H, et al. Variation in the percent "
    "emphysema-like in a healthy, nonsmoking multiethnic sample. Ann Am "
    "Thorac Soc 2014;11:898-907.",

    "Regan EA, Lynch DA, Curran-Everett D, et al. Clinical and radiologic "
    "disease in smokers with normal spirometry. JAMA Intern Med "
    "2015;175:1539-1549.",

    "Woodruff PG, Barr RG, Bleecker E, et al. Clinical significance of "
    "symptoms in smokers with preserved pulmonary function. N Engl J Med "
    "2016;374:1811-1821.",

    "Fortis S, Strand M, Bhatt SP, et al. Respiratory exacerbations and lung "
    "function decline in people with smoking history and normal spirometry. "
    "Am J Respir Crit Care Med 2025;211:957-965.",

    "Abdo M, Reck M, Stiebeler S, et al. Clinically relevant change in "
    "airway wall thickness to identify disease activity in COPD and smokers "
    "at risk. Eur Respir J 2026;67:2900306.",
]


def build(doc):
    H1(doc, "REFERENCES")
    for i, ref in enumerate(REFERENCES, start=1):
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Inches(0.4)
        p.paragraph_format.first_line_indent = Inches(-0.4)
        r = p.add_run(f"{i}. {ref}")
        r.font.name = FONT_NAME
        r.font.size = Pt(BODY_FS)
