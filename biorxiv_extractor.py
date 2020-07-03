import requests
from bs4 import BeautifulSoup
import string
import argparse
import json


REQUESTS_HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:64.0) Gecko/20100101 Firefox/64.0'}

METHODS = ['METHOD',
           'METHODS',
           'MATERIALSANDMETHODS',
           'MATERIALANDMETHOD',
           'MATERIALANDMETHODS',
           'MATERIALSANDMETHOD',
           'METHODSANDMATERIALS',
           'METHODANDMATERIALS',
           'METHODSANDMATERIAL',
           'METHODSANDMATERIAL'
           'PROCEDURE',
           'EXPERIMENTALPROCEDURE',
           'EXPERIMENTALPROCEDURES',
           'STUDYDESIGN',
           'MATERIALSMETHODS',
           'MATERIALMETHOD',
           'MATERIALMETHODS',
           'MATERIALSMETHOD',
           'METHODSMATERIALS',
           'METHODMATERIALS',
           'METHODSMATERIAL',
           'METHODSMATERIAL']

RESULTS = ['RESULTS',
           'RESULT',
           'EXPERIMENTALRESULT',
           'EXPERIMENTALRESULTS',
           'FINDING',
           'FINDINGS']

DISCUSSION = ['DISCUSSION',
              'DISCUSSIONS']


class Preprint:
    def __init__(self, doi):
        med_url = 'http://medrxiv.org/cgi/content/short/' + doi.split('10.1101/')[1]
        bio_url = 'http://biorxiv.org/cgi/content/short/' + doi.split('10.1101/')[1]
        if requests.get(med_url).status_code == 404:
            self.url = bio_url
        else:
            self.url = med_url
        self.html = None

    def get_json(self):
        if self.html is None:
            html = requests.get(self.url + '.full', headers=REQUESTS_HEADERS).text
            self.html = html
        else:
            html = self.html
        if 'data-panel-name="article_tab_full_text"' not in html:
            raise TypeError('Full-text HTML was not found at the URL ({}). Is the DOI valid, and has the HTML been released yet?'.format(self.url))
        text = {}
        soup = BeautifulSoup(html, 'html.parser')
        for header in soup.find_all('h2')[:-2]:
            text[header.text] = ''
            for tag in header.parent:
                if tag.name == 'p':
                    text[header.text] += tag.text + ' '
                if tag.name == 'div' and ('subsection' in tag['class'] or 'section' in tag['class']):
                    for subtag in tag:
                        if subtag.name == 'p':
                            text[header.text] += subtag.text + ' '
                        if subtag.name == 'div':
                            for subsubtag in subtag:
                                if subsubtag.name == 'p':
                                    text[header.text] += subsubtag.text + ' '
        return {key: text[key].strip() for key in text}

    def get_text(self, include_headers=True):
        if self.html is None:
            html = requests.get(self.url + '.full', headers=REQUESTS_HEADERS).text
            self.html = html
        else:
            html = self.html
        if 'data-panel-name="article_tab_full_text"' not in html:
            raise TypeError('Full-text HTML was not found at the URL ({}). Is the DOI valid, and has the HTML been released yet?'.format(self.url))
        text = ''
        soup = BeautifulSoup(html, 'html.parser')
        for header in soup.find_all('h2')[:-2]:
            if include_headers:
                text += header.text + ' '
            for tag in header.parent:
                if tag.name == 'p':
                    text += tag.text + ' '
                if tag.name == 'div' and ('subsection' in tag['class'] or 'section' in tag['class']):
                    for subtag in tag:
                        if subtag.name == 'h3' and include_headers:
                            text += subtag.text + ' '
                        if subtag.name == 'p':
                            text += subtag.text + ' '
                        if subtag.name == 'div':
                            for subsubtag in subtag:
                                if subsubtag.name == 'p':
                                    text += subsubtag.text + ' '
                                if subsubtag.name == 'h4' and include_headers:
                                    text += subsubtag.text + ' '
        return text.strip()

    def get_section(self, section):
        json_text = self.get_json()
        for header in json_text:
            cleaned = ''.join([letter for letter in header.upper() if letter in string.ascii_uppercase])
            if cleaned in section:
                return json_text[header]

    def download_pdf(self, file):
        with open(file, 'wb') as f:
            f.write(requests.get(self.url + '.full.pdf', headers=REQUESTS_HEADERS).content)

    def get_metadata(self):
        html = requests.get(self.url, headers=REQUESTS_HEADERS).text
        authors = []
        for line in html.split('\n'):
            if '<span class="nlm-surname">' in line:
                for author in line.split('<span class="nlm-surname">')[1:]:
                    authors.append(author.split('<')[0])
                break
        title = ''
        for line in html.split('\n'):
            if '<meta name="DC.Title"' in line:
                title = line.split('<meta name="DC.Title" content="')[1].split('"')[0]
                break
        date = ''
        for line in html.split('\n'):
            if '<meta name="DC.Date"' in line:
                date = line.split('<meta name="DC.Date" content="')[1].split('"')[0]
                break
        return {'authors': authors, 'title': title, 'date': date}


def get_doi_list(start_page, stop_page):
    dois = []
    for i in range(start_page, stop_page):
        html = requests.get('https://www.biorxiv.org/content/early/recent?page=' + str(i), headers=REQUESTS_HEADERS).text
        for line in html.split('\n'):
            if '<span class="highwire-cite-title">' in line:
                dois.append(line.split('/content/')[1].split('v')[0])
    return dois


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extracts data from medRxiv and bioRxiv preprints.')
    parser.add_argument('doi', help='doi of preprint to download')
    parser.add_argument('format', choices=['pdf', 'json', 'txt'], help='specify which format to download paper in')
    parser.add_argument('--noheader', action='store_const', default=False, const=True, help='remove all headers from output text (works only if format is txt)')
    parser.add_argument('--section', choices=['methods', 'results', 'discussion'], help='extract a specific section (works only if format is txt)')
    parser.add_argument('outfile')
    args = parser.parse_args()

    preprint = Preprint(args.doi)
    if args.format == 'pdf':
        preprint.download_pdf(args.outfile)
    elif args.format == 'json':
        with open(args.outfile, 'w', encoding='utf-8') as f:
            f.write(json.dumps(preprint.get_json()))
    else:
        text = ''
        if args.section is None:
            text = preprint.get_text(include_headers=(not args.noheader))
        else:
            if args.section == 'methods':
                text = preprint.get_section(METHODS)
            elif args.section == 'results':
                text = preprint.get_section(RESULTS)
            else:
                text = preprint.get_section(DISCUSSION)
        with open(args.outfile, 'w', encoding='utf-8') as f:
            f.write(text)