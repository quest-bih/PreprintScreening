import os, glob
import requests
from fastai.vision import *
import argparse
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from barzooka import Barzooka

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Runs barzooka graph type detection on a set of pdfs in folder.')
    parser.add_argument('pdf_folder', help="folder that contains the pdfs")
    parser.add_argument('save_filename', help="where the results should be saved")
    parser.add_argument('--iiif_folder', help="folder under which pdfs are reached with the iiif server",
                        default="")
    parser.add_argument('--tmp_folder', help="tmp folder for extracted images from pdfs",
                        default="./tmp/")
    parser.add_argument("--iiif", help="use iiif server for image prediction",
                        action="store_true")
    args = parser.parse_args()

    barzooka = Barzooka()
    barzooka.predict_from_folder(args.pdf_folder, args.save_filename,
                                 args.iiif_folder, args.iiif,
                                 args.tmp_folder)
