import os
import requests
from fastai.vision import *
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


os.environ['NO_PROXY'] = '127.0.0.1'
current_folder = '2020-06-29_2020-07-05'
pdf_folder = '../weekly_lists/' + current_folder + '/PDFs/'
save_filename = '../weekly_lists/' + current_folder + \
    '/results/barzooka_preprint_results_' + current_folder + '.csv'


class Barzooka(object):
    def __init__(self):

        super(Barzooka, self).__init__()
        self.learner = load_learner(path='.', file='export.pkl')
        self.iiif_url = "http://127.0.0.1:8182/iiif/2/" + \
                        "{}:{}.pdf/full/560,560/0/default.png?page={}"
        self.re_pg = re.compile(r'Index: \d+, Size: (\d+)')

    def detection_iiif(self, paper_id, folder, debug=False):
        """Pull images from iiif server
        """
        pages = self.__count_pages(paper_id, folder)
        if pages == 0:
            return self.__empty_result(paper_id, folder)

        images = [open_image(io.BytesIO(requests.get(self.iiif_url.format(folder, paper_id, pg)).content)) 
                  for pg in range(1, pages + 1)]

        classes_detected = self.__predict_img_list(images)
        classes_detected['paper_id'] = paper_id.replace("%2b", "/")
        classes_detected['folder'] = folder

        return classes_detected

    def __empty_result(self, paper_id, folder):
        classes_detected = dict()
        classes_detected['bar'] = 0
        classes_detected['pie'] = 0
        classes_detected['hist'] = 0
        classes_detected['bardot'] = 0
        classes_detected['box'] = 0
        classes_detected['dot'] = 0
        classes_detected['violin'] = 0
        classes_detected['paper_id'] = paper_id.replace("%2b", "/")
        classes_detected['folder'] = folder

        return classes_detected

    def __predict_img_list(self, images):
        """Predicts graph types for each image & returns pages with bar graphs
        """
        page_predictions = np.array([self.__predict_graph_type(images[idx])
                                     for idx in range(0, len(images))])

        # add 1 to page idx such that page counting starts at 1
        bar_pages = np.where(page_predictions == 'bar')[0] + 1
        pie_pages = np.where(page_predictions == 'pie')[0] + 1
        hist_pages = np.where(page_predictions == 'hist')[0] + 1
        bardot_pages = np.where(page_predictions == 'bardot')[0] + 1
        box_pages = np.where(page_predictions == 'box')[0] + 1
        dot_pages = np.where(page_predictions == 'dot')[0] + 1
        violin_pages = np.where(page_predictions == 'violin')[0] + 1
        positive_pages = hist_pages.tolist() + bardot_pages.tolist() + \
            box_pages.tolist() + dot_pages.tolist() + violin_pages.tolist()

        if len(positive_pages) > 0:
            # remove duplicates & sort
            positive_pages = list(set(positive_pages))
            positive_pages.sort()

        classes_detected = dict()
        classes_detected['bar'] = len(bar_pages.tolist())
        classes_detected['pie'] = len(pie_pages.tolist())
        classes_detected['hist'] = len(hist_pages.tolist())
        classes_detected['bardot'] = len(bardot_pages.tolist())
        classes_detected['box'] = len(box_pages.tolist())
        classes_detected['dot'] = len(dot_pages.tolist())
        classes_detected['violin'] = len(violin_pages.tolist())

        return classes_detected

    def __predict_graph_type(self, img):
        """Use fastai model on each image to predict types of pages
        """
        class_names = {
            "0": ["approp"],
            "1": ["bar"],
            "2": ["bardot"],
            "3": ["box"],
            "4": ["dot"],
            "5": ["hist"],
            "6": ["other"],
            "7": ["pie"],
            "8": ["text"],
            "9": ["violin"]
        }

        pred_class, pred_idx, outputs = self.learner.predict(img)

        if pred_idx.sum().tolist() == 0:
            # if there is no predicted class (=no class over threshold)
            # give out class with highest prediction probability
            highest_pred = str(np.argmax(outputs).tolist())
            pred_class = class_names[highest_pred]
        else:
            pred_class = pred_class.obj  # extract class name as text

        return(pred_class)

    def __count_pages(self, paper_id, folder):
        """cantaloupe iiif server returns the highest page index with an error
        if out of range is requested
        """
        url = self.iiif_url.format(folder, paper_id, "1000")
        page = self.__req_internal(url)
        try:
            count = self.re_pg.findall(page)[0]
        except:
            count = 0

        return int(count)

    def __req_internal(self, url):
        http = urllib3.PoolManager(cert_reqs='CERT_NONE')
        page = http.request('get', url, timeout=120)
        return page.data.decode('utf-8')


def get_pdf_list(pdf_folder):
    """Searches PDF folder for all PDF filenames and returns them
       as dataframe"""
    pdf_list = []
    for root, dirs, files in os.walk(pdf_folder):
        for filename in files:
            paper_dict = {"paper_id": filename[:-4].replace("+", "%2b")}
            pdf_list.append(paper_dict)

    pdf_table = pd.DataFrame(pdf_list)
    return pdf_table


if __name__ == '__main__':
    paper_id = "10.1101%2b2020.06.11.20127019"
    folder = '06_15-06_21'
    barzooka = Barzooka()
    # print(barzooka.detect_graph_types_from_iiif(paper_id, folder))

    current_folder = '2020-06-29_2020-07-05'
    pdf_folder = '../weekly_lists/' + current_folder + '/PDFs/'
    save_filename = '../weekly_lists/' + current_folder + \
                    '/results/test_results_' + current_folder + '.csv'

    pdf_table = get_pdf_list(pdf_folder)
    pdf_table = pdf_table.iloc[:2]

    barzooka_results_list = []
    with open(save_filename, "w") as f:
        f.write("bar,pie,hist,bardot,box,dot,violin,paper_id,folder\n")

    for index, row in pdf_table.iterrows():
        paper_id = row['paper_id']
        print(paper_id)
        barzooka_result = barzooka.detection_iiif(paper_id, current_folder)
        barzooka_results_list.append(barzooka_result)

        print(pd.DataFrame([barzooka_result]))
        result_row = pd.DataFrame([barzooka_result])
        result_row.to_csv(save_filename, mode='a', header=False)

    barzooka_results = pd.DataFrame(barzooka_results_list)

