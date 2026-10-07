class_name TestAnswers
extends DecisionProvider
## Answers player decisions from a list (DECLINED once it runs out) and
## records each question, with how many events had happened when it was
## asked. Set [member use_ai] to answer like the AI instead.

var answers: Array[int] = []
var remember_next: bool = false
var use_ai: bool = false
var asked: Array[DecisionRequest] = []
var events_when_asked: Array[int] = []
var log: TestEvents


func choose(request: DecisionRequest) -> int:
	asked.append(request)
	if log != null:
		events_when_asked.append(log.types.size())
	request.remember = remember_next
	if use_ai:
		return request.ai_choice
	return answers.pop_front() if not answers.is_empty() else DecisionRequest.DECLINED


func titles() -> Array[String]:
	var out: Array[String] = []
	for r in asked:
		out.append(r.title)
	return out
