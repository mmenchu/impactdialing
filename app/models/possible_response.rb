class PossibleResponse < ActiveRecord::Base
  belongs_to :question, inverse_of: :possible_responses
  has_many :answers
  # validates :question, presence: true
  validates :value, presence: true
  validates :possible_response_order, presence: true, numericality: true

  default_scope { order("possible_response_order") }

  def stats(answer_count, total_count)
    number_of_answers = answer_count[self.id] || 0
    total_answers = total_count[question_id] || 1
    {answer: value, number: number_of_answers, percentage:  total_answers == 0 ? 0 : (number_of_answers * 100 / total_answers)}
  end

  def answered?
    answers.first != nil
  end

  def self.possible_response_count(questions)
    possible_responses = PossibleResponse.select("id").where("question_id in (?)",questions)
    Answer.select("possible_response_id").where("possible_response_id in (?)",possible_responses).group("possible_response_id").count
  end

  def self.response_for_answers(answers)
    ids = answers.collect{|a| a.try(:possible_response).try(:id) }
    PossibleResponse.select("question_id, value").where("id in (?)", ids).order('question_id')
  end

  def self.possible_response_text(question_ids, answers, possible_responses)
    answers ||= []
    answered_data = answers.each_with_object({}) do |a, memo|
      memo[a['question_id']] = a['possible_response_id']
    end
    question_ids.map do |question_id|
      answered_data.has_key?(question_id) ? (possible_responses[answered_data[question_id]] || "") : ""
    end
  end
end

# ## Schema Information
#
# Table name: `possible_responses`
#
# ### Columns
#
# Name                           | Type               | Attributes
# ------------------------------ | ------------------ | ---------------------------
# **`id`**                       | `integer`          | `not null, primary key`
# **`question_id`**              | `integer`          |
# **`keypad`**                   | `integer`          |
# **`value`**                    | `string(255)`      |
# **`retry`**                    | `boolean`          | `default(FALSE)`
# **`possible_response_order`**  | `integer`          |
# **`external_id_field`**        | `string(255)`      |
#
# ### Indexes
#
# * `index_possible_responses_question_keypad_possible_response_order`:
#     * **`question_id`**
#     * **`keypad`**
#     * **`possible_response_order`**
#
