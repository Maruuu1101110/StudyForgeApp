class FlashCard:
    def __init__(self, question, answer):
        self.question = question
        self.answer = answer

    def __repr__(self):
        return f"FlashCard(question='{self.question}', answer='{self.answer}')"

# Sample JSON-like data (what you'd expect from the file)
sets = [
    {"question": "Who am I?", "answer": "EJ"},
    {"question": "What is Flutter?", "answer": "A UI toolkit"},
    {"question": "Purpose of setState?", "answer": "To update the UI"},
]

# Flashcard objects
listOfFlashCards = [FlashCard(item["question"], item["answer"]) for item in sets]

# Print to verify
print(listOfFlashCards)
