const dateTimeComparator = (valueA, valueB, nodeA, nodeB, isDescending) => {
    const parseDate = (date) => {
        const [startDate] = date.split("-");
        return new Date(startDate.trim());
    };

    const dateA = parseDate(valueA);
    const dateB = parseDate(valueB);

    if (dateA.getTime() === dateB.getTime()) return 0;

    return dateA.getTime() > dateB.getTime() ? 1 : -1;
};

export default {
  dateTimeComparator,
};